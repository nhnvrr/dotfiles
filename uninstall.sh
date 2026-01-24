#!/usr/bin/env bash

set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || { echo "This uninstall is only supported on macOS."; exit 1; }

BREW_BIN="${BREW_BIN:-$(command -v brew || true)}"

cli_tools=(
  awscli
  bat
  delve
  atuin
  firebase-cli
  gh
  git
  go
  btop
  jq
  neovim
  node
  pgcli
  pnpm
  postgresql
  rust
  sentry-cli
  starship
  terraform
  tmux
  zsh-autosuggestions
  zsh-syntax-highlighting
)

cask_apps=(
  ollama
  codex
  telegram
  obsidian
  alacritty
  brave-browser
  ledger-wallet
  docker-desktop
  aws-vpn-client
  visual-studio-code
)

font_casks=(
  font-geist-mono-nerd-font
  font-jetbrains-mono-nerd-font
)

if [[ -n "${BREW_BIN}" ]]; then
  echo "Removing CLI formulas..."
  "${BREW_BIN}" uninstall --ignore-dependencies "${cli_tools[@]}" || true
  echo "Removing cask apps..."
  "${BREW_BIN}" uninstall --cask --ignore-dependencies "${cask_apps[@]}" || true
  echo "Removing font casks..."
  "${BREW_BIN}" uninstall --cask --ignore-dependencies "${font_casks[@]}" || true
else
  echo "Homebrew is not installed; skipping brew removals."
fi

echo "Removing bun installation..."
rm -rf "${HOME}/.bun"

echo "Removing symlinks..."
rm -f "${HOME}/.zshrc"
rm -f "${HOME}/.hushlogin"
rm -f "${HOME}/.tmux.conf"
rm -f "${HOME}/.config/starship/starship.toml"
rm -f "${HOME}/.config/pgcli/config"
rm -f "${HOME}/.config/alacritty/alacritty.toml"
rm -f "${HOME}/.config/gh/config.yml"

echo "Removing config directories..."
rm -rf "${HOME}/.config/starship" "${HOME}/.config/pgcli" "${HOME}/.config/nvim" "${HOME}/.config/gh" "${HOME}/.config/alacritty"

echo "Removing tool caches (non-cask)..."
rm -rf "${HOME}/.codex"

echo "Note: Git global config changes were not reverted."

echo "Uninstall complete."
