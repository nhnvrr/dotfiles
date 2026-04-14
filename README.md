# dotfiles

macOS dotfiles and bootstrap script for terminal, editor, shell, and window management setup.

## What `install.sh` does

Running [`install.sh`](./install.sh) on macOS will:

- install Homebrew if it is missing
- run `brew update`
- install missing Homebrew formulae
- install missing Homebrew casks
- install missing font casks
- install `bun` only if it is not already present
- configure global Git settings
- configure Go `GOPATH` and `GOPRIVATE`
- link shell and app config files into `$HOME`
- copy the Neovim config into `$HOME/.config/nvim`
- switch the default shell to `fish` if needed

The script is intended to be rerunnable. Formulae, casks, fonts, and `bun` are checked before installation.

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

- `fish` as the default shell, with aliases, `fnm`, and `bun` path setup
- `ghostty` with `Monaspace Neon`, custom light/dark themes, roomier padding, and `Cmd+Shift+R` to reload config
- `starship` as the shell prompt
- `tmux` with vi-style navigation, clipboard integration, and fish as the default shell inside tmux
- `neovim` with LSP, Treesitter, Telescope, Neo-tree, formatting, DAP, and Mason-managed tools
- `hammerspoon` for a few app layout hotkeys

### Hammerspoon shortcuts

Current window layout bindings:

- `Cmd+Option+1`: `Slack` left `2/9`, `Chrome` right `7/9`
- `Cmd+Option+2`: `Terminal` left `1/3`, `Chrome` right `2/3`
- `Cmd+Option+3`: `Terminal` left `2/7`, `Postico 2` right `5/7`
- `Cmd+Option+9`: `Dia` left `5/7`, `Terminal` right `2/7`
- `Cmd+Option+0`: `Terminal` left `5/7`, `Dia` right `2/7`
- `Cmd+Option+-`: `VS Code` left `5/7`, `Dia` right `2/7`

### Homebrew formulae

`install.sh` installs these formulae when missing:

- `awscli`
- `bash`
- `bat`
- `btop`
- `delve`
- `fish`
- `fnm`
- `gh`
- `git`
- `go`
- `jq`
- `neovim`
- `pnpm`
- `postgresql`
- `rust`
- `sentry-cli`
- `starship`
- `terraform`
- `tmux`

### Apps and desktop tools

`install.sh` installs these casks when missing:

- `aws-vpn-client`
- `claude`
- `claude-code`
- `codex`
- `docker-desktop`
- `ghostty`
- `hammerspoon`
- `ledger-wallet`
- `linear-linear`
- `nordvpn`
- `ollama`
- `postico`
- `slack`
- `telegram`
- `visual-studio-code`
- `zen`

### Fonts

The script installs these font casks when missing:

- `font-monaspace`
- `font-jetbrains-mono-nerd-font`

## Managed files

These files are linked into your home directory:

- [`fish/config.fish`](./fish/config.fish) -> `$HOME/.config/fish/config.fish`
- [`fish/completions/aws.fish`](./fish/completions/aws.fish) -> `$HOME/.config/fish/completions/aws.fish`
- [`ghostty/config.ghostty`](./ghostty/config.ghostty) -> `$HOME/.config/ghostty/config.ghostty`
- [`ghostty/themes/nh-light`](./ghostty/themes/nh-light) -> `$HOME/.config/ghostty/themes/nh-light`
- [`ghostty/themes/nh-dark`](./ghostty/themes/nh-dark) -> `$HOME/.config/ghostty/themes/nh-dark`
- [`tmux/tmux.conf`](./tmux/tmux.conf) -> `$HOME/.tmux.conf`
- [`starship/starship.toml`](./starship/starship.toml) -> `$HOME/.config/starship.toml`
- [`hammerspoon/init.lua`](./hammerspoon/init.lua) -> `$HOME/.hammerspoon/init.lua`

This directory is copied:

- [`nvim`](./nvim) -> `$HOME/.config/nvim`

If present, this file is also linked:

- `gh/config.yml` -> `$HOME/.config/gh/config.yml`

## Notes

- The setup only supports macOS.
- The script may prompt for `sudo` when adding `fish` to `/etc/shells`.
- The script may prompt when changing your login shell with `chsh`.
- Because the Neovim config is copied, rerunning the script will resync `$HOME/.config/nvim` from this repo.
- [`One Dark Half.terminal`](./One%20Dark%20Half.terminal) is included as a Terminal theme file but is not imported automatically.
