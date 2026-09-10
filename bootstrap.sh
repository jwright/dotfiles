#!/usr/bin/env bash
#
# bootstrap.sh — take a fresh macOS install to a working development machine.
#
# Nothing needs to exist beforehand. curl ships with macOS and this repo is
# public, so the only input is the command itself; everything the script needs
# after that (1Password, an SSH key) it installs or creates.
#
# Written check-first: every phase asserts its desired end state before doing any
# work, so the script is idempotent and safe to re-run.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jwright/dotfiles/main/bootstrap.sh | bash
#   curl -fsSL <same url> | bash -s -- --verify    # assertions only, changes nothing
#
# Env hooks (see "Testing" in the README):
#   SKIP_SYSTEM        decline the system-wide installs in preflight
#   SKIP_BUNDLE        decline brew bundle
#   ASSUME_SIGNED_IN   treat the 1Password gate as passed
#   DOTFILES           where the repo lives (default ~/Projects/dotfiles)
#   SSH_KEY_TITLE      name for a generated 1Password SSH key item

set -euo pipefail

SELF_URL="https://raw.githubusercontent.com/jwright/dotfiles/main/bootstrap.sh"
REPO_HTTPS="https://github.com/jwright/dotfiles.git"
REPO_SSH="git@github.com:jwright/dotfiles.git"

VERIFY_ONLY=false
[[ "${1:-}" == "--verify" ]] && VERIFY_ONLY=true

DOTFILES="${DOTFILES:-$HOME/Projects/dotfiles}"
AGENT_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
SSH_KEY_TITLE="${SSH_KEY_TITLE:-$(scutil --get ComputerName 2>/dev/null || hostname -s)}"

# ---------------------------------------------------------------------------
# output helpers
# ---------------------------------------------------------------------------

log()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m  ok\033[0m   %s\n' "$1"; }
todo() { printf '\033[1;33m  todo\033[0m %s\n' "$1"; }
fail() { printf '\033[1;31m  fail\033[0m %s\n' "$1"; }

# Piped through curl, stdin is the script — so prompts have to come off the tty.
# With no tty (CI, a test harness) this answers no and the phase reports instead.
ask() {
  [[ -r /dev/tty ]] || return 1
  local reply
  printf '\033[1;35m  ??\033[0m   %s [y/N] ' "$1" >/dev/tty
  read -r reply </dev/tty || return 1
  [[ "$reply" == [yY]* ]]
}

# ---------------------------------------------------------------------------
# assertions — these define "done" for each phase
# ---------------------------------------------------------------------------

have()          { command -v "$1" >/dev/null 2>&1; }
clt_present()   { xcode-select -p >/dev/null 2>&1; }
brew_present()  { have brew; }
cask_present()  { brew list --cask "$1" >/dev/null 2>&1; }
app_present()   { [[ -d "/Applications/$1.app" ]]; }
# Seen to fail transiently while the app was locking, which would bounce you back
# to the manual gate for no reason, so give it a second chance.
op_signed_in() {
  op account list 2>/dev/null | grep -q . && return 0
  sleep 1
  op account list 2>/dev/null | grep -q .
}
ssh_agent_on()  { [[ -S "$AGENT_SOCK" ]]; }

# ssh-add exits non-zero when the agent has no identities, which is exactly the
# question being asked. Point it at 1Password's socket, not whatever is inherited.
agent_has_key() { SSH_AUTH_SOCK="$AGENT_SOCK" ssh-add -l >/dev/null 2>&1; }

# ssh -T against GitHub exits 1 even on success, so match the greeting instead.
github_ssh_ok() {
  SSH_AUTH_SOCK="$AGENT_SOCK" ssh -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 -T git@github.com 2>&1 | grep -q "successfully authenticated"
}

brew_shellenv() {
  # Apple silicon puts brew in /opt/homebrew, Intel in /usr/local
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# ---------------------------------------------------------------------------
# preflight — phases 1-3 get 1Password onto the machine
#
# These are the only phases that install system-wide, which is why SKIP_SYSTEM
# exists: a $HOME override does not contain them.
# ---------------------------------------------------------------------------

log "preflight 1/3 — Xcode command line tools"
if clt_present; then
  ok "already installed"
elif $VERIFY_ONLY; then
  fail "missing"
elif [[ "${SKIP_SYSTEM:-false}" == true ]]; then
  todo "SKIP_SYSTEM set, not installing"
else
  # Non-blocking: opens the GUI installer, then we wait it out.
  xcode-select --install 2>/dev/null || true
  until clt_present; do
    todo "waiting on the CLT installer to finish..."
    sleep 20
  done
  ok "installed"
fi

log "preflight 2/3 — Homebrew"
brew_shellenv
if brew_present; then
  ok "$(brew --version | head -1)"
elif $VERIFY_ONLY; then
  fail "missing"
elif [[ "${SKIP_SYSTEM:-false}" == true ]]; then
  todo "SKIP_SYSTEM set, not installing"
else
  # This prompts once for sudo. It is the only credential prompt we can't dodge.
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew_shellenv
  ok "installed"
fi

log "preflight 3/3 — 1Password"
for cask in 1password 1password-cli; do
  if cask_present "$cask"; then
    ok "$cask present"
  elif [[ "$cask" == 1password ]] && app_present "1Password"; then
    ok "1Password present (installed outside brew)"
  elif $VERIFY_ONLY; then
    fail "$cask missing"
  else
    # 1password-cli ships as a pkg and will ask for sudo here.
    if [[ "${SKIP_SYSTEM:-false}" == true ]]; then
      todo "SKIP_SYSTEM set, not installing $cask"
    else
      brew install --cask "$cask"
      ok "$cask installed"
    fi
  fi
done

have op && ok "op $(op --version)"

# ---------------------------------------------------------------------------
# phase 4 — the manual gate
# ---------------------------------------------------------------------------

log "phase 4 — 1Password account"
# ASSUME_SIGNED_IN is a test hook: op keeps its account state under $HOME, so a
# sandboxed $HOME can never pass this gate and the later phases would never run.
if [[ "${ASSUME_SIGNED_IN:-false}" == true ]]; then
  ok "ASSUME_SIGNED_IN set, treating the gate as passed"
elif op_signed_in; then
  ok "signed in"
else
  todo "sign in manually — this part is deliberately not scriptable:"
  todo "  1. open -a 1Password"
  todo "  2. on a device already signed in: Settings > Accounts > Set Up Another Device"
  todo "     (no other device? use the Emergency Kit's Secret Key)"
  todo "  3. scan the QR code, enter your master password"
  todo "  4. Settings > Security  -> enable Touch ID unlock"
  todo "  5. Settings > Developer -> enable CLI integration + SSH agent"
  app_present "1Password" && ! $VERIFY_ONLY && open -a 1Password
  echo
  # Piped through curl there is no local copy to re-run, and the repo is not
  # cloned yet — so name whichever invocation actually works.
  if [[ -f "${BASH_SOURCE[0]:-}" ]]; then
    todo "re-run '${BASH_SOURCE[0]}' once that's done."
  else
    todo "re-run once that's done:"
    todo "  curl -fsSL $SELF_URL | bash"
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# phase 5 — an SSH key, generated into 1Password if there isn't one
#
# Not required to bootstrap: the clone below is HTTPS on a public repo. This is
# what makes pushing work afterwards, so it asks rather than blocks.
# ---------------------------------------------------------------------------

log "phase 5 — SSH key"
if ! ssh_agent_on; then
  todo "agent socket missing — enable Settings > Developer > Use the SSH agent"
elif agent_has_key; then
  ok "agent is offering $(SSH_AUTH_SOCK="$AGENT_SOCK" ssh-add -l | wc -l | tr -d ' ') key(s)"
elif $VERIFY_ONLY; then
  fail "no key in the agent"
elif ask "no SSH key in the agent. Generate one in 1Password now?"; then
  op item create --category "SSH Key" --title "$SSH_KEY_TITLE" \
    --ssh-generate-key ed25519 --vault Private >/dev/null
  ok "created 1Password SSH key item '$SSH_KEY_TITLE'"
  todo "if the agent still does not offer it, allow its vault under"
  todo "  1Password > Settings > Developer > SSH agent"
else
  todo "skipped — create one in 1Password (New Item > SSH Key) and re-run"
fi

# Register it with GitHub. gh is not installed yet (it arrives with brew bundle,
# below), so this is the browser and a paste rather than `gh ssh-key add`.
if agent_has_key; then
  if github_ssh_ok; then
    ok "GitHub accepts the key"
  elif $VERIFY_ONLY; then
    fail "GitHub does not accept the key yet"
  else
    todo "GitHub does not have this key yet. Its public half:"
    SSH_AUTH_SOCK="$AGENT_SOCK" ssh-add -L | sed 's/^/       /'
    if ask "open github.com/settings/ssh/new to paste it?"; then
      open "https://github.com/settings/ssh/new" 2>/dev/null || true
      ask "added it? (checking again)" && {
        github_ssh_ok && ok "GitHub accepts the key" || todo "still not accepted; re-run later"
      }
    fi
  fi
fi

# ---------------------------------------------------------------------------
# phase 6 — git + ssh config
# ---------------------------------------------------------------------------

log "phase 6 — git + ssh config"
SSH_CONF="$HOME/.ssh/config"

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
elif $VERIFY_ONLY; then
  fail "git signing not configured"
else
  git config --global gpg.format ssh
  git config --global gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
  git config --global commit.gpgsign true
  ok "git commit signing via 1Password"
fi

# ---------------------------------------------------------------------------
# phase 7 — the repo itself, then everything in the Brewfile
# ---------------------------------------------------------------------------

log "phase 7 — dotfiles"
if [[ -d "$DOTFILES" ]]; then
  ok "already cloned"
elif $VERIFY_ONLY; then
  fail "not cloned"
else
  # HTTPS on purpose: a public repo needs no credentials, so nothing about this
  # clone depends on the SSH work above having succeeded.
  mkdir -p "$(dirname "$DOTFILES")"
  git clone "$REPO_HTTPS" "$DOTFILES"
  ok "cloned"
fi

# Pushing wants SSH, so upgrade the remote once a key is actually working.
if [[ -d "$DOTFILES/.git" ]] && ! $VERIFY_ONLY && agent_has_key && github_ssh_ok; then
  if [[ "$(git -C "$DOTFILES" remote get-url origin)" == https://* ]]; then
    git -C "$DOTFILES" remote set-url origin "$REPO_SSH"
    ok "origin switched to SSH"
  fi
fi

if [[ -f "$DOTFILES/Brewfile" ]] && ! $VERIFY_ONLY; then
  if [[ "${SKIP_BUNDLE:-false}" == true ]]; then
    todo "SKIP_BUNDLE set, not running brew bundle"
  else
    log "brew bundle"
    brew bundle --file="$DOTFILES/Brewfile"
    ok "everything else installed"
  fi
fi

# ---------------------------------------------------------------------------
# phase 8 — link the dotfiles into $HOME
# ---------------------------------------------------------------------------

log "phase 8 — dotfile symlinks"

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
