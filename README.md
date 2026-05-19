# dotfiles

macOS dotfiles and bootstrap script for terminal, editor, and shell setup.

## What `install.sh` does

Running [`install.sh`](./install.sh) on macOS will:

- install Homebrew if it is missing
- run `brew update`
- install everything declared in [`Brewfile`](./Brewfile) via `brew bundle`
- install globally configured `mise` tools (pinned in [`mise/config.toml`](./mise/config.toml))
- configure global Git settings
- prepare the Go workspace
- link config files into `$HOME` (Neovim config included)
- switch the default shell to `fish` if needed (adds it to `/etc/shells` first)

The script is intended to be rerunnable. `brew bundle` and `mise install` are idempotent.

## Commands

Run from the repository root:

```bash
./install.sh
```

Skip Homebrew package and app installation and only apply config files:

```bash
./install.sh --skipBrew
```

If the script is not executable in a fresh checkout:

```bash
bash ./install.sh
```

## Tooling

This repo configures:

- `fish` as the default shell, with aliases, git abbreviations, `mise`, and Go workspace setup
- `starship` as the shell prompt
- `tmux` with vi-style navigation and clipboard integration
- `neovim` with LSP, Treesitter, fzf-lua, formatting, diagnostics, and Mason-managed tools

### Homebrew packages

All Homebrew formulae, casks, and fonts are declared in [`Brewfile`](./Brewfile). To inspect or update the list, edit that file directly.

Useful commands:

```bash
brew bundle check --file=./Brewfile     # report what's missing
brew bundle --file=./Brewfile           # install missing items
brew bundle cleanup --file=./Brewfile   # uninstall what's not in the Brewfile
```

### Mise tools

Pinned in [`mise/config.toml`](./mise/config.toml): `node`, `aws-cli`, `bun`, `go`, `terraform`. `pnpm` is enabled through Node's Corepack after `mise install`.

## Managed files

These files are linked into your home directory:

- [`fish/config.fish`](./fish/config.fish) -> `$HOME/.config/fish/config.fish`
- [`mise/config.toml`](./mise/config.toml) -> `$HOME/.config/mise/config.toml`
- [`tmux/tmux.conf`](./tmux/tmux.conf) -> `$HOME/.tmux.conf`
- [`starship/starship.toml`](./starship/starship.toml) -> `$HOME/.config/starship.toml`
- [`ghostty/config`](./ghostty/config) -> `$HOME/.config/ghostty/config`
- [`nvim/init.lua`](./nvim/init.lua) -> `$HOME/.config/nvim/init.lua`
- [`nvim/lua`](./nvim/lua) -> `$HOME/.config/nvim/lua`
- [`nvim/keymaps.md`](./nvim/keymaps.md) -> `$HOME/.config/nvim/keymaps.md`

If present, this file is also linked:

- `gh/config.yml` -> `$HOME/.config/gh/config.yml`

## Notes

- The setup only supports macOS.
- The script may prompt when changing your login shell with `chsh`.
- The Neovim config is symlinked, so edits in `$HOME/.config/nvim` are reflected directly in this repo. `lazy.nvim`'s `lazy-lock.json` is gitignored.
