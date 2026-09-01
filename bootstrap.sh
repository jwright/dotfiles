#!/usr/bin/env bash
#
# bootstrap.sh — take a fresh macOS install to the point where 1Password
# can bootstrap everything else (git access, SSH keys, secrets).
#
# Written check-first: every phase asserts its desired end state before
# doing any work, so the script is idempotent and safe to re-run.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jwright/dotfiles/main/bootstrap.sh | bash
#   ./bootstrap.sh --verify     # run assertions only, change nothing

set -euo pipefail

VERIFY_ONLY=false
[[ "${1:-}" == "--verify" ]] && VERIFY_ONLY=true

# ---------------------------------------------------------------------------
# output helpers
# ---------------------------------------------------------------------------

log()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m  ok\033[0m   %s\n' "$1"; }
todo() { printf '\033[1;33m  todo\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31m  fail\033[0m %s\n' "$1"; }

# ---------------------------------------------------------------------------
# assertions — these define "done" for each phase
# ---------------------------------------------------------------------------

have()          { command -v "$1" >/dev/null 2>&1; }
clt_present()   { xcode-select -p >/dev/null 2>&1; }
brew_present()  { have brew; }
cask_present()  { brew list --cask "$1" >/dev/null 2>&1; }
app_present()   { [[ -d "/Applications/$1.app" ]]; }
op_signed_in()  { op account list 2>/dev/null | grep -q .; }
ssh_agent_on()  { [[ -S "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]]; }

brew_shellenv() {
  # Apple silicon puts brew in /opt/homebrew, Intel in /usr/local
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# ---------------------------------------------------------------------------
# phase 1 — Xcode command line tools
# ---------------------------------------------------------------------------

log "Xcode command line tools"
if clt_present; then
  ok "already installed"
elif $VERIFY_ONLY; then
  fail "missing"
else
  # Non-blocking: opens the GUI installer, then we wait it out.
  xcode-select --install 2>/dev/null || true
  until clt_present; do
    todo "waiting on the CLT installer to finish..."
    sleep 20
  done
  ok "installed"
fi

# ---------------------------------------------------------------------------
# phase 2 — Homebrew
# ---------------------------------------------------------------------------

log "Homebrew"
brew_shellenv
if brew_present; then
  ok "$(brew --version | head -1)"
elif $VERIFY_ONLY; then
  fail "missing"
else
  # This prompts once for sudo. It is the only credential prompt we can't dodge.
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew_shellenv
  ok "installed"
fi

# ---------------------------------------------------------------------------
# phase 3 — 1Password app + CLI
# ---------------------------------------------------------------------------

log "1Password"
for cask in 1password 1password-cli; do
  if cask_present "$cask"; then
    ok "$cask present"
  elif $VERIFY_ONLY; then
    fail "$cask missing"
  else
    # 1password-cli ships as a pkg and will ask for sudo here.
    brew install --cask "$cask"
    ok "$cask installed"
  fi
done

have op && ok "op $(op --version)"

# ---------------------------------------------------------------------------
# phase 4 — the manual gate
# ---------------------------------------------------------------------------

log "1Password account"
if op_signed_in; then
  ok "signed in: $(op account list --format=json 2>/dev/null | grep -o '"url":"[^"]*"' | head -1)"
else
  todo "sign in manually — this part is deliberately not scriptable:"
  todo "  1. open -a 1Password"
  todo "  2. on a device already signed in: Settings > Accounts > Set Up Another Device"
  todo "  3. scan the QR code, enter your master password"
  todo "  4. Settings > Security  -> enable Touch ID unlock"
  todo "  5. Settings > Developer -> enable CLI integration + SSH agent"
  app_present "1Password" && ! $VERIFY_ONLY && open -a 1Password
  echo
  todo "re-run './bootstrap.sh --verify' once that's done."
  exit 0
fi

# ---------------------------------------------------------------------------
# phase 5 — everything downstream of a working 1Password
# ---------------------------------------------------------------------------

log "SSH agent"
if ssh_agent_on; then
  ok "agent socket is live"
else
  todo "enable Settings > Developer > Use the SSH agent, then re-run"
fi

log "git + ssh config"
SSH_CONF="$HOME/.ssh/config"
AGENT_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

if [[ -f "$SSH_CONF" ]] && grep -q "2BUA8C4S2C" "$SSH_CONF"; then
  ok "ssh config already points at the 1Password agent"
elif $VERIFY_ONLY; then
  fail "ssh config not wired up"
else
  mkdir -p "$HOME/.ssh"
  cat >> "$SSH_CONF" <<EOF

Host *
  IdentityAgent "$AGENT_SOCK"
EOF
  ok "ssh config updated"
fi

if git config --global --get gpg.ssh.program >/dev/null 2>&1; then
  ok "git signing already configured"
elif ! $VERIFY_ONLY; then
  git config --global gpg.format ssh
  git config --global gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
  git config --global commit.gpgsign true
  ok "git commit signing via 1Password"
fi

# ---------------------------------------------------------------------------
# phase 6 — hand off to the Brewfile
# ---------------------------------------------------------------------------

log "dotfiles"
DOTFILES="$HOME/Projects/dotfiles"
if [[ -d "$DOTFILES" ]]; then
  ok "already cloned"
elif $VERIFY_ONLY; then
  fail "not cloned"
else
  # SSH now works because the key lives in 1Password, not on disk.
  mkdir -p "$(dirname "$DOTFILES")"
  git clone git@github.com:jwright/dotfiles.git "$DOTFILES"
  ok "cloned"
fi

if [[ -f "$DOTFILES/Brewfile" ]] && ! $VERIFY_ONLY; then
  log "brew bundle"
  brew bundle --file="$DOTFILES/Brewfile"
  ok "everything else installed"
fi

# ---------------------------------------------------------------------------
# phase 7 — link the dotfiles into $HOME
# ---------------------------------------------------------------------------

log "dotfile symlinks"

# "done" means $HOME/.zshrc is a symlink pointing back into the repo.
links_done() {
  [[ -L "$HOME/.zshrc" && "$(readlink "$HOME/.zshrc")" == "$DOTFILES"/* ]]
}

if links_done; then
  ok "already linked into $DOTFILES"
elif $VERIFY_ONLY; then
  fail "not linked"
elif [[ ! -f "$DOTFILES/Rakefile" ]]; then
  todo "no Rakefile in $DOTFILES, skipping"
elif ! have rake; then
  fail "rake not found; run 'rake link' in $DOTFILES by hand"
else
  # Note: rake link replaces whatever sits at each target, including real
  # files. That is what you want on a fresh Mac and worth a look anywhere else.
  ( cd "$DOTFILES" && rake link )
  ok "linked into $HOME"
fi

echo
log "done"
