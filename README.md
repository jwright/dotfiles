# dotfiles

Machine setup for a fresh macOS install. Public on purpose — the whole point is
that a brand-new Mac with no credentials on it can fetch and run this.

## New machine

```sh
curl -fsSL https://raw.githubusercontent.com/jwright/dotfiles/main/bootstrap.sh | bash
```

That gets you to a working 1Password, at which point you sign in by hand (once),
flip two toggles, and re-run:

```sh
./bootstrap.sh --verify
```

`--verify` runs every assertion without changing anything, so it tells you which
phase you're stuck on.

## What it does

| Phase | Does | Scriptable |
|---|---|---|
| 1 | Xcode command line tools | yes |
| 2 | Homebrew | yes (one sudo prompt) |
| 3 | `1password` + `1password-cli` casks | yes (one sudo prompt) |
| 4 | Sign in to the 1Password account | **no — by hand** |
| 5 | SSH agent socket, git commit signing | yes |
| 6 | `git clone` this repo, `brew bundle` | yes |
| 7 | `rake link` — symlink the dotfiles into `$HOME` | yes |

Phase 4 is the only real gate. A new device needs the Secret Key, which lives in
the Emergency Kit or in a setup QR code shown by a device already signed in.
Nothing in this repo can substitute for that, and it shouldn't be able to.

The two toggles under 1Password → Settings → Developer (CLI integration, SSH
agent) are GUI-only. The app does keep settings in a JSON file, but it's
undocumented and gets rewritten, so it isn't worth automating two clicks.

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
delete — there is no VM state to unwind.

Three env hooks make that possible, and each one marks a boundary the sandbox
cannot cross on its own:

| Hook | Guards | Why |
|---|---|---|
| `SKIP_SYSTEM` | phases 1-3 | Command line tools, Homebrew and casks install system-wide; a `$HOME` override does not contain them |
| `SKIP_BUNDLE` | `brew bundle` | Same reason — it installs for real |
| `ASSUME_SIGNED_IN` | phase 4 | `op` keeps account state under `$HOME`, so a sandbox can never pass the gate and phases 5-7 would never run |

Pass `--system` / `--bundle` to opt back in when you actually want those.

### Full-fidelity testing

The sandbox cannot test phases 1-3, because a fresh machine is the only honest
way to test "install Homebrew". For that, a disposable macOS VM on Apple silicon
(`tart`, backed by Virtualization.framework) is the usual answer:

```sh
brew install cirruslabs/cli/tart
tart clone <current macos base image> base   # one large download, kept as the golden copy
tart clone base scratch && tart run scratch  # test here
tart delete scratch                          # reset
```

Keep `base` pristine and always test in a clone of it — that makes reset a
delete rather than an uninstall. Note the base image is tens of GB, and `tart`
is not installed on this machine.

## Nothing secret goes here

This repo is public. No hostnames, no tokens, no private keys, no internal
URLs. Anything that needs a secret reads it at runtime via `op read`, e.g.:

```sh
export SOME_TOKEN="$(op read 'op://Private/Some Item/credential')"
```

SSH keys live in 1Password and are served through its agent — `~/.ssh` should
contain a `config` and nothing else.
