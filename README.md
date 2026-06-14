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
- Configures global `~/.gitconfig` (identity, aliases, pull-rebase, SSH commit signing, histogram diff, zdiff3 conflict style)
- Generates an `ed25519` SSH key if missing, registers it with the macOS Keychain via `~/.ssh/config`, and copies the pubkey to the clipboard for GitHub
- Symlinks all config files into `$HOME` (see [Managed files](#managed-files))
- Applies a small set of macOS defaults (fast key-repeat, no press-and-hold, Finder show extensions, Dock autohide, screenshots into `~/Pictures/Screenshots`)
- Installs the Ioskeley Term Nerd Font from its GitHub release (no Homebrew cask available)
- Switches the login shell to `/bin/zsh` if needed (uses `dscl` to read the real login shell, not `$SHELL`)

The `link_file` helper backs up any pre-existing regular file at the destination to `<dst>.bak.<timestamp>` before replacing it with a symlink — your hand-edited configs won't disappear silently.

## First run on a fresh Mac

After `install.sh` exits cleanly:

1. **Paste the SSH pubkey on GitHub** — it's already on your clipboard. Add it at <https://github.com/settings/ssh/new> as both an authentication key AND a signing key (so your signed commits show up as Verified).
2. **Authenticate the GitHub CLI:** `gh auth login` (script reminds you if not authenticated).
3. **Grant Accessibility permission to Hammerspoon** on first launch (System Settings → Privacy & Security → Accessibility). Required for window management hotkeys.
4. **Restart your terminal** so the new login shell, fonts, and macOS defaults all take effect.

## Tooling

| Layer | Tool | Config file |
|---|---|---|
| Shell | zsh | [`zsh/zshrc`](./zsh/zshrc) |
| Prompt | starship | [`starship/starship.toml`](./starship/starship.toml) |
| Terminal | Alacritty | [`alacritty/alacritty.toml`](./alacritty/alacritty.toml) |
| Multiplexer | tmux | [`tmux/tmux.conf`](./tmux/tmux.conf) |
| Editor | Neovim (LSP, treesitter, conform, gitsigns, fzf-lua, mason) | [`nvim/`](./nvim/) |
| Window mgmt | Hammerspoon | [`hammerspoon/init.lua`](./hammerspoon/init.lua) |
| Runtime mgr | mise | [`mise/config.toml`](./mise/config.toml) |
| Font | IoskeleyMonoTerm Nerd Font | installed from GitHub release |
| Theme | Kintsugi Flared (cohesive across all surfaces) | [`alacritty/themes/`](./alacritty/themes/), [`nvim/colors/`](./nvim/colors/), [`vscode/kintsugi-flared/`](./vscode/kintsugi-flared/) |

`zsh/zshrc` notes:
- Defines `dev` / `work` / `side` aliases that spawn (or switch to) a named tmux session with a fixed CWD.
- Auto-exports `AWS_PROFILE=work` when inside the `work` tmux session (inside the interactive block only — non-interactive subshells don't inherit it).
- Wraps `claude` so that `CLAUDE_CONFIG_DIR=~/.claude-work` is used in the `work` session, letting two Claude Code subscriptions stay logged in side-by-side.

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
| `zsh/zshrc` | `~/.zshrc` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `nvim/init.lua` | `~/.config/nvim/init.lua` |
| `nvim/lua` | `~/.config/nvim/lua` |
| `nvim/colors` | `~/.config/nvim/colors` |
| `nvim/keymaps.md` | `~/.config/nvim/keymaps.md` |
| `hammerspoon/init.lua` | `~/.hammerspoon/init.lua` |
| `gh/config.yml` (if present) | `~/.config/gh/config.yml` |

The Neovim config is symlinked, so edits inside `~/.config/nvim` are reflected directly in the repo.

## What is NOT managed

- **VSCode `settings.json` / `keybindings.json`** — only the Kintsugi theme is versioned here; everything else is unmanaged (`Settings Sync` lives elsewhere).
- **`~/.aws/config`** — keep your own AWS profiles where you want them; the repo only sets `AWS_PROFILE` based on tmux session.
- **`~/.claude/`** (and the optional `~/.claude-work/`) — Claude Code config is user-level state, not versioned. Bootstrap a work account with `CLAUDE_CONFIG_DIR=~/.claude-work claude` then `/login`.

## Notes

- Supports macOS only.
- The script may prompt for your password when `chsh` runs.
- Designed to be safe to rerun: every step either no-ops or moves existing state aside before replacing it.
