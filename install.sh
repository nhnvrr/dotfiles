#!/usr/bin/env bash

set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This setup is only supported on macOS."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_DIR="${ROOT_DIR}/config"

brew_bin="$(command -v brew || true)"

if [ -z "${brew_bin}" ]; then
  echo "Homebrew not found; installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -x "/opt/homebrew/bin/brew" ]; then
    brew_bin="/opt/homebrew/bin/brew"
  elif [ -x "/usr/local/bin/brew" ]; then
    brew_bin="/usr/local/bin/brew"
  else
    echo "Homebrew installation failed: brew not found on PATH."
    exit 1
  fi
fi

eval "$("${brew_bin}" shellenv)"

echo "Installing Homebrew packages..."
"${brew_bin}" update

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
"${brew_bin}" install "${cli_tools[@]}"

apps=(
  "docker-desktop"
  "google-chrome"
  "ledger-wallet"
  "notion"
  "obsidian"
  "ollama"
  "slack"
  "spotify"
  "telegram"
  "visual-studio-code"
  "whatsapp"
)
"${brew_bin}" install --cask "${apps[@]}"

echo "Configuring git..."
git config --global user.name "Nicolas Navarro"
git config --global user.email "navarropaeznicolas@gmail.com"
git config --global init.defaultBranch "main"
git config --global push.default "tracking"
git config --global push.autoSetupRemote "true"
git config --global branch.autosetuprebase "always"
git config --global color.ui "true"
git config --global core.askPass ""
git config --global credential.helper "osxkeychain"
git config --global github.user "nhnvrr"
git config --global alias.cleanup "!git branch --merged | grep -v '\\*\\|master\\|develop' | xargs -n 1 -r git branch -d"
git config --global alias.prettylog "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
git config --global alias.root "rev-parse --show-toplevel"

echo "Configuring Go environment..."
mkdir -p "${HOME}/Develop/go"
go env -w GOPATH="${HOME}/Develop/go"
go env -w GOPRIVATE="github.com/nhnvrr"

echo "Linking config files..."
ln -sf "${CONFIG_DIR}/zsh/.zshrc" "${HOME}/.zshrc"

mkdir -p "${HOME}/.config/starship"
ln -sf "${CONFIG_DIR}/starship/starship.toml" "${HOME}/.config/starship/starship.toml"

mkdir -p "${HOME}/.config/pgcli"
ln -sf "${CONFIG_DIR}/pgcli/config" "${HOME}/.config/pgcli/config"

if [ -f "${CONFIG_DIR}/gh/config.yml" ]; then
  mkdir -p "${HOME}/.config/gh"
  ln -sf "${CONFIG_DIR}/gh/config.yml" "${HOME}/.config/gh/config.yml"
fi

echo "macOS standalone setup complete."
