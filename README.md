# dotfiles

Machine setup for a fresh macOS install. Public on purpose — the whole point is
that a brand-new Mac with no credentials on it can fetch and run this.

## New machine

```sh
curl -fsSL https://raw.githubusercontent.com/jwright/dotfiles/main/bootstrap.sh | bash
```

That is the whole thing. Nothing needs to exist first: `curl` ships with macOS,
this repo is public, and everything else — 1Password, an SSH key, the clone — the
script installs or creates.

It runs until it reaches the one step that cannot be scripted, signing in to
1Password, prints exactly what to do, and stops. Do those steps and run **the
same command again**. Every phase asserts before acting, so finished work is
skipped and it picks up where it left off.

Along the way it will ask for your login password twice (once for Homebrew, once
for the `1password-cli` pkg), wait out Apple's GUI installer for the command line
tools, and offer to generate an SSH key if the 1Password agent has none. The slow
part is `brew bundle` at the end.

When it finishes, open a new shell — `$HOME` is now symlinked to the repo.

### Checking where you stand

```sh
curl -fsSL https://raw.githubusercontent.com/jwright/dotfiles/main/bootstrap.sh | bash -s -- --verify
```

`--verify` only asserts. It changes nothing and continues nothing; it just tells
you which phase you are stuck on.

### Confirming afterwards

```sh
readlink ~/.zshrc                 # -> ~/Projects/dotfiles/.zshrc
git -C ~/Projects/dotfiles status # should be clean; see Known issues if not
```

## What it does

| Phase | Does | Scriptable |
|---|---|---|
| preflight 1 | Xcode command line tools | yes |
| preflight 2 | Homebrew | yes (one sudo prompt) |
| preflight 3 | `1password` + `1password-cli` casks | yes (one sudo prompt) |
| 4 | Sign in to the 1Password account | **no — by hand** |
| 5 | SSH key: generate into 1Password if the agent has none, register with GitHub | yes (asks first) |
| 6 | SSH config, git commit signing | yes |
| 7 | Clone this repo, `brew bundle` | yes |
| 8 | `rake link` — symlink the dotfiles into `$HOME` | yes |

Preflight exists to get 1Password onto the machine, because everything after it
depends on 1Password working. Those three phases are also the only ones that
install system-wide.

Phase 4 is the only real gate. A new device needs the Secret Key, which lives in
the Emergency Kit or in a setup QR code shown by a device already signed in.
Nothing in this repo can substitute for that, and it shouldn't be able to.

The two toggles under 1Password → Settings → Developer (CLI integration, SSH
agent) are GUI-only. The app does keep settings in a JSON file, but it's
undocumented and gets rewritten, so it isn't worth automating two clicks.

Phase 5 asks before it creates anything. It is also not on the critical path:
phase 7 clones over **HTTPS**, which a public repo needs no credentials for, so a
machine with no SSH key still bootstraps fine. The key is what makes *pushing*
work, and `origin` is switched from HTTPS to SSH once GitHub accepts it.

## Testing

`bin/test-bootstrap` runs the script against a throwaway `$HOME`, so the phases
that matter can be exercised without touching the real machine:

```sh
bin/test-bootstrap --signed-in     # full run in a sandbox
bin/test-bootstrap --verify        # assertions only
bin/test-bootstrap --keep ...      # re-run against the same sandbox (idempotency)
bin/test-bootstrap --shell         # poke around inside it
bin/test-bootstrap --reset         # rm -rf the sandbox
```

The sandbox is a plain directory (`/tmp/dotfiles-sandbox`), so resetting is a
delete — there is no VM state to unwind. It seeds from the working tree, not a
clone, so uncommitted edits get tested.

Env hooks make that possible, and each one marks a boundary the sandbox cannot
cross on its own:

| Hook | Guards | Why |
|---|---|---|
| `SKIP_SYSTEM` | preflight | Command line tools, Homebrew and casks install system-wide; a `$HOME` override does not contain them |
| `SKIP_BUNDLE` | `brew bundle` | Same reason — it installs for real |
| `ASSUME_SIGNED_IN` | phase 4 | `op` keeps account state under `$HOME`, so a sandbox can never pass the gate and phases 5-8 would never run |
| `DOTFILES` | phase 7 | Points the clone somewhere disposable |
| `SSH_KEY_TITLE` | phase 5 | Names a generated key item (defaults to the computer name) |

Pass `--system` / `--bundle` to opt back in when you actually want those.

Phase 5's prompts read from `/dev/tty`, because piping through `curl` leaves
stdin holding the script. With no tty they answer no, so a sandboxed run reports
what it would have asked instead of hanging.

### Full-fidelity testing

The sandbox cannot test preflight, because a fresh machine is the only honest way
to test "install Homebrew". For that, a disposable macOS VM on Apple silicon
(`tart`, backed by Virtualization.framework) is the usual answer:

```sh
brew install cirruslabs/cli/tart
tart clone <current macos base image> base   # one large download, kept as the golden copy
tart clone base scratch && tart run scratch  # test here
tart delete scratch                          # reset
```

Keep `base` pristine and always test in a clone of it — that makes reset a delete
rather than an uninstall. Note the base image is tens of GB.

## Known issues

**Git commit signing does not survive the run.** Phase 6 writes `gpg.format`,
`gpg.ssh.program` and `commit.gpgsign` into `~/.gitconfig`; phase 8 then replaces
that file with a symlink to the repo's copy, which has none of them. So signing
is silently off when the run ends. Check with:

```sh
git config --global --get commit.gpgsign
```

Related: once `~/.gitconfig` is a symlink, any `git config --global` writes
*through* it into the repo's tracked file. If `git status` in the repo is dirty
after a run, that is why — check before committing, so a local path does not end
up in a public repo. The fix is to move machine-specific git config into an
included `~/.gitconfig.local`, which is not done yet.

## Nothing secret goes here

This repo is public. No hostnames, no tokens, no private keys, no internal
URLs. Anything that needs a secret reads it at runtime via `op read`, e.g.:

```sh
export SOME_TOKEN="$(op read 'op://Private/Some Item/credential')"
```

SSH keys live in 1Password and are served through its agent — `~/.ssh` should
contain a `config` and nothing else.
