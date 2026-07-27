# Source of truth for this machine's tooling.
# `brew bundle cleanup --force` uninstalls ANYTHING not declared here.
#
# Where a tool goes: does its version need to match the project's?
#   yes -> mise/config.toml   (node, go, rust, python, terraform, bun, aws-cli)
#   no  -> here               (jq, fzf, ripgrep, git, bat)
# Having them in both places makes the version depend on where you run: in an
# interactive shell mise wins, in a script with a clean PATH brew wins.

# zsh itself is macOS's /bin/zsh — not a formula, so it can't drift.
brew "starship"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

brew "tmux"
brew "neovim"

brew "fzf"
brew "fd"
brew "ripgrep"
brew "bat"
brew "jq"
brew "zoxide"
brew "eza"

brew "git"
brew "gh"
brew "git-delta"

# libpq ships psql without the Postgres server.
brew "libpq"

brew "mise"

# Excepción a la regla de arriba: por versión iría en mise, pero mise no
# funcionó. Ojo que mise inyecta su bin antes que /opt/homebrew en el PATH, así
# que un shim de corepack bajo node/*/bin tapa este binario sin avisar.
brew "pnpm"

brew "yt-dlp"
brew "htop"
brew "fastfetch"

cask "ghostty"
# Mono variant (NFM): icons take one cell, so `ls -la` columns stay aligned.
cask "font-jetbrains-mono-nerd-font"

cask "visual-studio-code"

cask "raycast"
cask "hammerspoon"

cask "google-chrome"

cask "docker-desktop"
cask "tableplus"
cask "bruno"
cask "proxyman"
cask "utm"

cask "aws-vpn-client"
cask "nosql-workbench"

cask "claude"
cask "claude-code@latest"
cask "chatgpt"
# The terminal agent. `codex-app`, the desktop app, is discontinued upstream.
cask "codex"

cask "cap"
cask "linear"
cask "notion"

cask "slack"
cask "whatsapp"
cask "telegram"

cask "ledger-wallet"
cask "nordvpn"
