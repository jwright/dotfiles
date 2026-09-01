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

## Nothing secret goes here

This repo is public. No hostnames, no tokens, no private keys, no internal
URLs. Anything that needs a secret reads it at runtime via `op read`, e.g.:

```sh
export SOME_TOKEN="$(op read 'op://Private/Some Item/credential')"
```

SSH keys live in 1Password and are served through its agent — `~/.ssh` should
contain a `config` and nothing else.
