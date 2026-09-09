# dotfiles

Machine setup for a fresh macOS install. Public on purpose — the whole point is
that a brand-new Mac with no credentials on it can fetch and run this.

## New machine

### Before you start

Two things the script cannot get for you:

- **A way into 1Password.** Either another device already signed in (it shows a
  setup QR code under Settings → Accounts → Set Up Another Device) or the
  Emergency Kit with the Secret Key.
- **Your SSH key already in 1Password, with the public half on GitHub.** Phase 6
  clones over SSH, so a key that GitHub has never seen will fail there.

Nothing else. No files copied over, no credentials on disk.

### 1. Open Terminal and run it

Use the stock **Terminal.app** — Ghostty arrives later, in `brew bundle`.

```sh
curl -fsSL https://raw.githubusercontent.com/jwright/dotfiles/main/bootstrap.sh | bash
```

That covers phases 1-3 and will ask for your **login password twice**: once for
Homebrew, once for the `1password-cli` pkg. The Xcode command line tools open
Apple's GUI installer; the script polls every 20 seconds and waits it out, so
leave it running.

It then stops on purpose at phase 4 and prints what to do.

### 2. Sign in to 1Password by hand

This is the one gate, and it is deliberately not scriptable:

1. `open -a 1Password` (the script does this for you)
2. On a device already signed in: Settings → Accounts → **Set Up Another Device**
3. Scan the QR code, enter your master password
4. Settings → Security → enable **Touch ID**
5. Settings → Developer → enable **CLI integration** and **the SSH agent**

Step 5 is what makes everything after this work. Without the SSH agent, phase 6
cannot clone.

### 3. Check where you stand

```sh
curl -fsSL https://raw.githubusercontent.com/jwright/dotfiles/main/bootstrap.sh | bash -s -- --verify
```

`--verify` only asserts — it changes nothing and continues nothing. Use it to see
which phase you are stuck on. Every line should read `ok` down to phase 5.

### 4. Run it again to finish

```sh
curl -fsSL https://raw.githubusercontent.com/jwright/dotfiles/main/bootstrap.sh | bash
```

Same command as step 1. Every phase asserts before acting, so the finished work
is skipped and it picks up at phase 5: ssh config, git signing, clone into
`~/Projects/dotfiles`, `brew bundle`, then `rake link`.

`brew bundle` is the slow part. Once it finishes, open a new shell — `$HOME` is
now symlinked to the repo.

### 5. Confirm

```sh
readlink ~/.zshrc                 # -> ~/Projects/dotfiles/.zshrc
git -C ~/Projects/dotfiles status # should be clean; see Known issues if not
```

### Known issues

**Git commit signing does not survive the run.** Phase 5 writes `gpg.format`,
`gpg.ssh.program` and `commit.gpgsign` into `~/.gitconfig`; phase 7 then replaces
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
