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
- `starship` as the shell prompt
- `tmux` with vi-style navigation, clipboard integration, and fish as the default shell inside tmux
- `neovim` with LSP, Treesitter, Telescope, Neo-tree, formatting, DAP, and Mason-managed tools
- `hammerspoon` for app launcher hotkeys

### Hammerspoon shortcuts

Current app shortcuts:

- `Cmd+Option+1`: `Terminal.app`
- `Cmd+Option+2`: `Google Chrome`
- `Cmd+Option+3`: `Visual Studio Code`
- `Cmd+Option+4`: `Postico`
- `Cmd+Option+5`: `Postman`
- `Cmd+Option+9`: `Brave Browser`
- `Cmd+Option+0`: `Linear`
- `Ctrl+Cmd+Option+R`: reload Hammerspoon

### Homebrew formulae

`install.sh` installs these formulae when missing:

- `awscli`
- `bash`
- `bat`
- `delve`
- `fd`
- `fish`
- `fnm`
- `fzf`
- `gh`
- `git`
- `go`
- `htop`
- `jq`
- `neovim`
- `pnpm`
- `postgresql`
- `rust`
- `sentry-cli`
- `starship`
- `terraform`
- `tmux`

### Other installed tools

`install.sh` also installs these tools outside Homebrew when they are missing:

- `bun` via the official install script

### Apps and desktop tools

`install.sh` installs these casks when missing:

- `aws-vpn-client`
- `claude`
- `claude-code`
- `codex`
- `brave-browser`
- `docker-desktop`
- `google-chrome`
- `hammerspoon`
- `ledger-wallet`
- `linear-linear`
- `nordvpn`
- `ollama-app`
- `postico`
- `postman`
- `telegram`
- `whatsapp`
- `visual-studio-code`

### Fonts

The script installs these font casks when missing:

- `font-monaspace`
- `font-jetbrains-mono-nerd-font`

## Managed files

These files are linked into your home directory:

- [`fish/config.fish`](./fish/config.fish) -> `$HOME/.config/fish/config.fish`
- [`fish/completions/aws.fish`](./fish/completions/aws.fish) -> `$HOME/.config/fish/completions/aws.fish`
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
