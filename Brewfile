# Source of truth for this machine's tooling.
# `brew bundle cleanup --force` uninstalls ANYTHING not declared here.
#
# Where a tool goes: does its version need to match the project's?
#   yes -> mise/config.toml   (node, go, rust, python, terraform, bun, aws-cli)
#   no  -> here               (jq, fzf, ripgrep, git, bat)
# Having them in both places makes the version depend on where you run: inside
# fish mise wins, in a script with a clean PATH brew wins.

brew "fish"
brew "tmux"
brew "neovim"

brew "fzf"
brew "fd"
brew "ripgrep"
brew "bat"
brew "jq"
brew "zoxide"

brew "git"
brew "gh"
brew "git-delta"

# libpq ships psql without the Postgres server.
brew "libpq"

brew "mise"

brew "yt-dlp"
brew "htop"
brew "fastfetch"

cask "alacritty"
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
