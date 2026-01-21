#!/usr/bin/env bash
set -euo pipefail

BREW_BIN="${BREW_BIN:-$(command -v brew || true)}"

cli_tools=(
  awscli
  bat
  delve
  firebase-cli
  gh
  git
  go
  htop
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

cask_tools=(
  codex
)

if [[ -n "${BREW_BIN}" ]]; then
  echo "Removing CLI formulas (other cask apps left intact)..."
  "${BREW_BIN}" uninstall --ignore-dependencies "${cli_tools[@]}" || true
  echo "Removing Codex cask..."
  "${BREW_BIN}" uninstall --cask --ignore-dependencies "${cask_tools[@]}" || true
else
  echo "Homebrew is not installed; skipping brew removals."
fi

echo "Removing bun installation..."
rm -rf "${HOME}/.bun"

echo "Removing symlinks..."
rm -f "${HOME}/.zshrc"
rm -f "${HOME}/.tmux.conf"
rm -f "${HOME}/.config/starship/starship.toml"
rm -f "${HOME}/.config/pgcli/config"
rm -f "${HOME}/.config/nvim/init.lua" "${HOME}/.config/nvim/.stylua.toml"
rm -f "${HOME}/.config/gh/config.yml"

echo "Removing config directories..."
rm -rf "${HOME}/.config/starship" "${HOME}/.config/pgcli" "${HOME}/.config/nvim" "${HOME}/.config/gh"

echo "Removing tool caches (non-cask)..."
rm -rf "${HOME}/.codex"

echo "Optional: remove fonts installed from this repo (uncomment to use):"
echo '# find "${HOME}/Library/Fonts" -maxdepth 1 -type f -name "GeistMono Nerd Font*.ttf" -delete'

echo "Uninstall complete."
