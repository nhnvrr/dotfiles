brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

brew "herdr"
# Not a second copy of the line below. herdr supervises agents over a socket API
# and dies with the terminal that started it; tmux is what holds a session across
# an ssh disconnect and the only one of the two that exists on a remote host.
# Read as alternatives they look redundant, and `brew bundle cleanup` would take
# this one out.
brew "tmux"

brew "neovim"

brew "vtsls"
brew "gopls"
brew "rust-analyzer"
brew "yaml-language-server"
brew "vscode-langservers-extracted"
brew "prettier"
brew "gofumpt"
brew "shfmt"
brew "stylua"
brew "taplo"
brew "lua-language-server"
brew "bash-language-server"
brew "shellcheck"
brew "golangci-lint"
brew "tree-sitter-cli"

brew "fzf"
brew "fd"
brew "bat"
brew "ripgrep"
brew "jq"
brew "duti"

brew "git"
brew "gh"
brew "git-delta"

brew "libpq"
brew "pgcli"
brew "redis"
brew "unixodbc"
brew "mise"

brew "cocoapods"
brew "watchman"
brew "delve"

brew "yt-dlp"
brew "ffmpeg"
brew "btop"
brew "fastfetch"

# The terminal. Its cask is `disable!`d since 2026-09-01 (fails the Gatekeeper
# check), so `brew bundle` refuses it and an uncommented line here would abort
# the whole run; the app is installed from the upstream DMG by hand — see the
# README, "Not managed". Kept here, commented, so the reason sits where a reader
# will look for the line.
# cask "alacritty"

cask "visual-studio-code"
cask "datagrip"
cask "postman"
cask "maccy"
cask "hammerspoon"
cask "google-chrome"
cask "docker-desktop"

cask "aws-vpn-client"

cask "claude-code@latest"
cask "claude"
cask "chatgpt"
cask "codex"

cask "cap"

cask "slack"
cask "discord"
cask "telegram"
cask "ledger-wallet"
