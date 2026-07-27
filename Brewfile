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
brew "lazygit"
brew "lazydocker"

# libpq ships psql without the Postgres server.
brew "libpq"

brew "mise"

# vesto-react-native needs both: cocoapods for the iOS build, watchman for
# Metro's file watching.
brew "cocoapods"
brew "watchman"

brew "sentry-cli"
# The Go debugger, installed as `dlv`. Go itself comes from mise.
brew "delve"

brew "yt-dlp"
# yt-dlp shells out to it to merge separate video and audio streams.
brew "ffmpeg"
brew "htop"
brew "fastfetch"

# Not declared on purpose — no evidence either way, and removing them blind is
# worse than carrying them:
#   bash      macOS ships 3.2; scripts here use #!/usr/bin/env bash
#   container Apple's Linux-container CLI
#   unixodbc  pulled in by a GUI client, kept until that's confirmed

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
