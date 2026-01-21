#!/usr/bin/env bash

set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || { echo "This setup is only supported on macOS."; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}"

BREW_BIN="${BREW_BIN:-$(command -v brew || true)}"

ensure_brew() {
  [[ -n "${BREW_BIN}" ]] && return
  echo "Homebrew not found; installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    BREW_BIN="/usr/local/bin/brew"
  else
    echo "Homebrew installation failed: brew not found on PATH."
    exit 1
  fi
}

link_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "${dst}")"
  ln -sf "${src}" "${dst}"
}

copy_dir() {
  local src="$1" dst="$2"
  mkdir -p "${dst}"
  rsync -a "${src}/" "${dst}/"
}

echo "Installing Homebrew packages..."
ensure_brew
eval "$("${BREW_BIN}" shellenv)"
"${BREW_BIN}" update

cli_tools=(
  awscli
  bat
  delve
  atuin
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
"${BREW_BIN}" install --formula "${cli_tools[@]}"

echo "Installing bun..."
curl -fsSL https://bun.sh/install | bash

apps=(
  "alacritty"
  "aws-vpn-client"
  "codex"
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
"${BREW_BIN}" install --cask "${apps[@]}"

echo "Installing Nerd Font (Geist Mono)..."
"${BREW_BIN}" install --cask font-geist-mono-nerd-font

echo "Configuring git..."
# Some environments (e.g., Nix home-manager) symlink ~/.config/git/config to a read-only location,
# so force Git to use a writable ~/.gitconfig for this setup.
export GIT_CONFIG_GLOBAL="${HOME}/.gitconfig"
touch "${GIT_CONFIG_GLOBAL}"
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
GOENV_PATH="${HOME}/Develop/go/goenv"
mkdir -p "$(dirname "${GOENV_PATH}")"
export GOENV="${GOENV_PATH}"
mkdir -p "${HOME}/Develop/go"
go env -w GOPATH="${HOME}/Develop/go"
go env -w GOPRIVATE="github.com/nhnvrr"

echo "Linking config files..."
link_file "${CONFIG_DIR}/zsh/.zshrc" "${HOME}/.zshrc"
link_file "${CONFIG_DIR}/tmux/tmux.conf" "${HOME}/.tmux.conf"
link_file "${CONFIG_DIR}/starship/starship.toml" "${HOME}/.config/starship.toml"
link_file "${CONFIG_DIR}/pgcli/config" "${HOME}/.config/pgcli/config"
copy_dir "${CONFIG_DIR}/nvim" "${HOME}/.config/nvim"
link_file "${CONFIG_DIR}/alacritty/alacritty.toml" "${HOME}/.config/alacritty/alacritty.toml"
if [[ -f "${CONFIG_DIR}/gh/config.yml" ]]; then
  link_file "${CONFIG_DIR}/gh/config.yml" "${HOME}/.config/gh/config.yml"
fi

echo "macOS standalone setup complete."
