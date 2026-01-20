#!/usr/bin/env bash
set -euo pipefail

BREW_BIN="${BREW_BIN:-$(command -v brew || true)}"

if [[ -z "${BREW_BIN}" ]]; then
  echo "Homebrew is not installed; nothing to uninstall."
  exit 0
fi

cli_tools=(
  awscli
  bat
  bun
  codex
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
)

echo "Removing CLI formulas (cask apps left intact)..."
"${BREW_BIN}" uninstall --ignore-dependencies "${cli_tools[@]}" || true

echo "Removing symlinks..."
rm -f "${HOME}/.zshrc"
rm -f "${HOME}/.tmux.conf"
rm -f "${HOME}/.config/starship/starship.toml"
rm -f "${HOME}/.config/pgcli/config"
rm -f "${HOME}/.config/nvim/init.lua" "${HOME}/.config/nvim/.stylua.toml"
rm -f "${HOME}/.config/gh/config.yml"

rmdir "${HOME}/.config/starship" "${HOME}/.config/pgcli" "${HOME}/.config/nvim" "${HOME}/.config/gh" 2>/dev/null || true

echo "Removing tool caches (non-cask)..."
rm -rf "${HOME}/.codex"

echo "Optional: remove fonts installed from this repo (uncomment to use):"
echo '# find "${HOME}/Library/Fonts" -maxdepth 1 -type f -name "GeistMono Nerd Font*.ttf" -delete'

echo "Uninstall complete."
