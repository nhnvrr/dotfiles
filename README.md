# dotfiles

macOS dotfiles and bootstrap script for terminal, editor, and shell setup.

## What `install.sh` does

Running [`install.sh`](./install.sh) on macOS will:

- install Homebrew if it is missing
- run `brew update`
- install missing Homebrew formulae
- install missing Homebrew casks
- install missing font casks
- install globally configured `mise` tools
- configure global Git settings
- prepare the Go workspace
- link shell config files into `$HOME`
- copy the Neovim config into `$HOME/.config/nvim`
- switch the default shell to macOS `zsh` if needed

The script is intended to be rerunnable. Formulae, casks, fonts, and `mise` tools are checked before installation.

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

- macOS `zsh` as the default shell, with aliases, history, completion, `mise`, and Go workspace setup
- `starship` as the shell prompt
- `tmux` with vi-style navigation, clipboard integration, and zsh as the default shell inside tmux
- `neovim` with LSP, Treesitter, fzf-lua, formatting, diagnostics, and Mason-managed tools

### Homebrew formulae

`install.sh` installs these formulae when missing:

- `bat`
- `fd`
- `fzf`
- `gh`
- `git`
- `jq`
- `mise`
- `neovim`
- `starship`
- `tmux`

### Mise tools

`install.sh` installs these globally configured tools through `mise`:

- `node`
- `aws-cli`
- `bun`
- `go`
- `terraform`

`pnpm` is enabled through Node's Corepack after `mise install`.

### Apps and desktop tools

`install.sh` installs these casks when missing:

- `aws-vpn-client`
- `chatgpt`
- `claude`
- `claude-code`
- `codex`
- `docker-desktop`
- `google-chrome`
- `kap`
- `ledger-wallet`
- `maccy`
- `nordvpn`
- `nosql-workbench`
- `ollama-app`
- `tableplus`
- `telegram`
- `visual-studio-code`
- `warp`
- `whatsapp`
- `zed`

### Fonts

The script installs these font casks when missing:

- `font-monaspace`
- `font-jetbrains-mono-nerd-font`

## Managed files

These files are linked into your home directory:

- [`zsh/zshrc`](./zsh/zshrc) -> `$HOME/.zshrc`
- [`mise/config.toml`](./mise/config.toml) -> `$HOME/.config/mise/config.toml`
- [`tmux/tmux.conf`](./tmux/tmux.conf) -> `$HOME/.tmux.conf`
- [`starship/starship.toml`](./starship/starship.toml) -> `$HOME/.config/starship.toml`

This directory is copied:

- [`nvim`](./nvim) -> `$HOME/.config/nvim`

If present, this file is also linked:

- `gh/config.yml` -> `$HOME/.config/gh/config.yml`

## Notes

- The setup only supports macOS.
- The script may prompt when changing your login shell with `chsh`.
- Because the Neovim config is copied, rerunning the script will resync `$HOME/.config/nvim` from this repo.
- [`One Dark Half.terminal`](./One%20Dark%20Half.terminal) is included as a Terminal theme file but is not imported automatically.
