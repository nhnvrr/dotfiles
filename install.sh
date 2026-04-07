#!/usr/bin/env bash

set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || { echo "This setup is only supported on macOS."; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}"

BREW_BIN="${BREW_BIN:-$(command -v brew || true)}"
SKIP_BREW=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skipBrew)
      SKIP_BREW=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--skipBrew]"
      exit 1
      ;;
  esac
done

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

if [[ "${SKIP_BREW}" == false ]]; then
  echo "Installing Homebrew packages..."
  ensure_brew
  eval "$("${BREW_BIN}" shellenv)"
  "${BREW_BIN}" update

  cli_tools=(
    awscli
    bash
    bat
    delve
    fnm
    fish
    gh
    git
    go
    btop
    jq
    neovim
    pnpm
    postgresql
    rust
    sentry-cli
    starship
    terraform
    tmux
  )
  "${BREW_BIN}" install --formula "${cli_tools[@]}"

  echo "Installing bun..."
  curl -fsSL https://bun.sh/install | bash

  apps=(
    "ollama"
    "codex"
    "claude"
    "claude-code"
    "ledger-wallet"
    "google-chrome"
    "gather"
    "telegram"
    "docker-desktop"
    "nordvpn"
    "linear-linear"
    "aws-vpn-client"
    "visual-studio-code"
    "hammerspoon"
    "alacritty"
  )
  "${BREW_BIN}" install --cask "${apps[@]}"

  echo "Installing fonts..."
  "${BREW_BIN}" install --cask font-monaspace font-jetbrains-mono font-geist-mono-nerd-font

  echo "Configuring git..."
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
else
  echo "Skipping Homebrew setup and tool installation (--skipBrew); only copying configuration."
fi

echo "Linking config files..."
link_file "${CONFIG_DIR}/fish/config.fish" "${HOME}/.config/fish/config.fish"
link_file "${CONFIG_DIR}/fish/completions/aws.fish" "${HOME}/.config/fish/completions/aws.fish"
link_file "${CONFIG_DIR}/tmux/tmux.conf" "${HOME}/.tmux.conf"
link_file "${CONFIG_DIR}/starship/starship.toml" "${HOME}/.config/starship.toml"
copy_dir "${CONFIG_DIR}/nvim" "${HOME}/.config/nvim"
if [[ -f "${CONFIG_DIR}/gh/config.yml" ]]; then
  link_file "${CONFIG_DIR}/gh/config.yml" "${HOME}/.config/gh/config.yml"
fi
link_file "${CONFIG_DIR}/hammerspoon/init.lua" "${HOME}/.hammerspoon/init.lua"
link_file "${CONFIG_DIR}/alacritty/alacritty.toml" "${HOME}/.config/alacritty/alacritty.toml"
link_file "${CONFIG_DIR}/alacritty/themes/dark.toml" "${HOME}/.config/alacritty/themes/dark.toml"
link_file "${CONFIG_DIR}/alacritty/themes/light.toml" "${HOME}/.config/alacritty/themes/light.toml"
cp "${CONFIG_DIR}/alacritty/themes/dark.toml" "${HOME}/.config/alacritty/themes/current.toml"
link_file "${CONFIG_DIR}/fish/functions/theme.fish" "${HOME}/.config/fish/functions/theme.fish"

if command -v fish >/dev/null 2>&1; then
  FISH_BIN="$(command -v fish)"
  if ! grep -qF "${FISH_BIN}" /etc/shells; then
    echo "Adding fish to /etc/shells..."
    echo "${FISH_BIN}" | sudo tee -a /etc/shells
  fi
  if [[ "${SHELL:-}" != "${FISH_BIN}" ]]; then
    echo "Changing default shell to fish..."
    chsh -s "${FISH_BIN}"
  fi
fi

echo "macOS standalone setup complete. 🧉"
