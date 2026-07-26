# dotfiles

macOS dotfiles and bootstrap script for terminal, editor, and shell setup.

## Prerequisites

You need Apple's command-line developer tools (provides `git`, `make`, `clang`, etc.) before running `install.sh`:

```bash
xcode-select --install
```

That's the only thing the script does **not** do for you.

## Quick start

```bash
git clone git@github.com:nhnvrr/dotfiles.git ~/Develop/dotfiles
cd ~/Develop/dotfiles
./install.sh
```

The script is idempotent — re-run it anytime to bring a machine back in sync. Run with `--skipBrew` to only re-link config files (skip Homebrew + tool installation):

```bash
./install.sh --skipBrew
```

## What `install.sh` does

- Installs Homebrew (if missing) and applies [`Brewfile`](./Brewfile) via `brew bundle`
- Installs mise-managed runtimes pinned in [`mise/config.toml`](./mise/config.toml) (Node, Bun, Go, AWS CLI, Terraform)
- Symlinks [`git/gitconfig`](./git/gitconfig) to `~/.gitconfig`, plus the global ignore and the allowed-signers file it references
- Generates an `ed25519` SSH key if missing, registers it with the macOS Keychain via `~/.ssh/config`, and copies the pubkey to the clipboard for GitHub
- Symlinks all config files into `$HOME` (see [Managed files](#managed-files))
- Applies a small set of macOS defaults (fast key-repeat, no press-and-hold, Finder show extensions, screenshots into `~/Screenshots`). The Dock is deliberately left alone — it's a visual preference, set it from System Settings
- Installs [Fisher](https://github.com/jorgebucaran/fisher) and the [Tide](https://github.com/IlanCosman/tide) prompt into fish, then seeds Tide's base config via `tide configure --auto`
- Registers fish in `/etc/shells` (needs `sudo`) and switches the login shell to it (uses `dscl` to read the real login shell, not `$SHELL`)
- Removes the stale `~/.zshrc` / `~/.config/starship.toml` symlinks left by the previous zsh + starship setup (only if they point into this repo)

The `link_file` helper backs up any pre-existing regular file at the destination to `<dst>.bak.<timestamp>` before replacing it with a symlink — your hand-edited configs won't disappear silently.

## First run on a fresh Mac

After `install.sh` exits cleanly:

1. **Paste the SSH pubkey on GitHub** — it's already on your clipboard. Add it at <https://github.com/settings/ssh/new> as both an authentication key AND a signing key (so your signed commits show up as Verified).
2. **Authenticate the GitHub CLI:** `gh auth login` (script reminds you if not authenticated).
3. **Grant Accessibility permission to Hammerspoon** on first launch (System Settings → Privacy & Security → Accessibility). Required for window management hotkeys.
4. **Open Alacritty** (not Terminal.app) — it picks up `alacritty/alacritty.toml`, JetBrains Mono Nerd Font, and fish as the login shell.

Note: the script prompts for your password twice — once for `sudo` (to add fish to `/etc/shells`) and once for `chsh`.

## Tooling

| Layer | Tool | Config file |
|---|---|---|
| Shell | fish | [`fish/config.fish`](./fish/config.fish) |
| Prompt | Tide (fish plugin, via Fisher) | overrides in [`fish/config.fish`](./fish/config.fish) |
| Terminal | Alacritty | [`alacritty/alacritty.toml`](./alacritty/alacritty.toml) |
| Multiplexer | tmux | [`tmux/tmux.conf`](./tmux/tmux.conf) |
| Editor | VS Code (`e` = `code --new-window`) — it's what handles the EC2 work: Remote-SSH, AWS Toolkit and SSM sessions. It's also what Hammerspoon's `cmd+alt+1` layout pairs with Chrome. Its config is user-level, not versioned here | — |
| `$EDITOR` | Neovim — commits, `git rebase -i`, fish's Ctrl-O. One file, one plugin (the theme), no LSP | [`nvim/init.lua`](./nvim/init.lua) |
| Database | `psql` as the primary client; TablePlus as the visual complement | [`psql/psqlrc`](./psql/psqlrc) |
| HTTP | `curl` via the `req` function; Bruno for exploratory work | [`fish/config.fish`](./fish/config.fish) |
| Git | versioned config, SSH-signed commits | [`git/gitconfig`](./git/gitconfig) |
| Window mgmt | Hammerspoon (app-pair layouts) + Raycast (launcher, clipboard, simple windows) | [`hammerspoon/init.lua`](./hammerspoon/init.lua) |
| Runtime mgr | mise — global versions plus per-project `.nvmrc` | [`mise/config.toml`](./mise/config.toml) |
| Font | JetBrains Mono, Nerd Font patched, size 15. The `Mono` (NFM) variant — its icons occupy a single cell, so `ls -la` columns stay aligned | cask `font-jetbrains-mono-nerd-font` |
| Theme | kanso-zen (dark-only): green-tinted palette on a near-black `#090E13` background. Alacritty defines the palette directly; nvim runs `kanso.nvim` (transparent), fzf and Tide follow in truecolor hex. tmux and `bat` inherit the terminal's ANSI palette. GUI editors keep their own user-level theme | [`alacritty/alacritty.toml`](./alacritty/alacritty.toml) |

`fish/config.fish` notes:
- Defines `dev` / `work` / `side` aliases that spawn (or switch to) a named tmux session with a fixed CWD.
- Always exports an explicit `AWS_PROFILE` — `work` inside the `work` tmux session, `personal` everywhere else (inside the `status is-interactive` block only, so non-interactive subshells don't inherit it). `~/.aws/config` has no `[default]` profile, so leaving it unset means every `aws` command fails with `NoCredentials`; setting it always also means Tide's `aws` item always draws, which is how you see which account you're pointed at.
- Provides `req` — curl with sane flags, piping the response through `jq` when it parses as JSON. There is deliberately no `~/.curlrc`: that file is read by *every* curl invocation, including the Homebrew installer's and any third-party script's.
- Wraps `claude` so that `CLAUDE_CONFIG_DIR=~/.claude-work` is used in the `work` session, letting two Claude Code subscriptions stay logged in side-by-side.
- Uses `abbr` (not `alias`) for the git shortcuts — they expand in place so you see the real command before running it, and the history stores the expanded form.
- Pins Tide's appearance with `set -g tide_*`. Tide itself stores config in *universal* variables, which aren't versionable; a global shadows a universal in fish's scoping, so this file stays the source of truth. `install.sh` only seeds the base config.

### Why fish

fish ships autosuggestions, syntax highlighting, prefix history search and completions natively — the previous zsh setup needed two Homebrew plugins plus ~40 lines of `zshrc` to get the same. `$CMD_DURATION` also replaced the hand-rolled `$SECONDS` timing hook for the long-command bell.

## Homebrew packages

All formulae, casks, and fonts are declared in [`Brewfile`](./Brewfile). To inspect or update:

```bash
brew bundle check --file=./Brewfile     # report what's missing
brew bundle --file=./Brewfile           # install missing items
brew bundle cleanup --file=./Brewfile   # uninstall what's not in the Brewfile
```

## Managed files

These are symlinked from the repo into `$HOME`:

| Repo path | Destination |
|---|---|
| `fish/config.fish` | `~/.config/fish/config.fish` |
| `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `nvim/init.lua` | `~/.config/nvim/init.lua` |
| `hammerspoon/init.lua` | `~/.hammerspoon/init.lua` |
| `git/gitconfig` | `~/.gitconfig` |
| `git/ignore` | `~/.config/git/ignore` |
| `git/allowed_signers` | `~/.config/git/allowed_signers` |
| `psql/psqlrc` | `~/.psqlrc` |
| `gh/config.yml` | `~/.config/gh/config.yml` |

The Neovim config is symlinked, so edits inside `~/.config/nvim` are reflected directly in the repo.

Because `~/.gitconfig` is a symlink, any `git config --global …` you run writes straight into `git/gitconfig` in this repo. That's deliberate — the change gets versioned instead of drifting in `$HOME` — but it does mean the repo shows as dirty after you touch git config.

Only `config.fish` is symlinked out of `~/.config/fish/` — Fisher and Tide **write** into `functions/`, `completions/` and `conf.d/`, so symlinking those would let a plugin install dirty the repo.

## What is NOT managed

- **Database credentials** — `~/.pgpass` holds them so `psql` doesn't prompt. It is a secrets file and is **never** versioned. Create it by hand, one connection per line, and lock it down or Postgres refuses to read it:

  ```
  hostname:port:database:username:password     # * works as a wildcard
  chmod 600 ~/.pgpass
  ```

- **VS Code** — config (`settings.json`, keybindings, theme) is user-level and not versioned here; Settings Sync lives elsewhere.
- **`~/.aws/config`** — keep your own AWS profiles where you want them; the repo only sets `AWS_PROFILE` based on tmux session.
- **`~/.claude/`** (and the optional `~/.claude-work/`) — Claude Code config is user-level state, not versioned. Bootstrap a work account with `CLAUDE_CONFIG_DIR=~/.claude-work claude` then `/login`.

## Notes

- Supports macOS only.
- The script prompts for your password twice: `sudo` (adding fish to `/etc/shells`) and `chsh` (switching the login shell).
- Rollback: `chsh -s /bin/zsh` restores the previous login shell. The old `zshrc` and `starship.toml` are still in git history.
- Designed to be safe to rerun: every step either no-ops or moves existing state aside before replacing it.
