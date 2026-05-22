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
  # Replace existing regular files/dirs with a symlink (idempotent for symlinks).
  if [[ -e "${dst}" && ! -L "${dst}" ]]; then
    rm -rf "${dst}"
  fi
  ln -sfn "${src}" "${dst}"
}

if [[ "${SKIP_BREW}" == false ]]; then
  echo "Installing Homebrew packages..."
  ensure_brew
  eval "$("${BREW_BIN}" shellenv)"
  "${BREW_BIN}" update

  echo "Applying Brewfile..."
  "${BREW_BIN}" bundle --file="${CONFIG_DIR}/Brewfile"

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

  echo "Preparing Go workspace..."
  mkdir -p "${HOME}/Develop/go/bin"
else
  echo "Skipping Homebrew setup and tool installation (--skipBrew); only linking configuration."
fi

echo "Linking config files..."
link_file "${CONFIG_DIR}/fish/config.fish" "${HOME}/.config/fish/config.fish"
link_file "${CONFIG_DIR}/mise/config.toml" "${HOME}/.config/mise/config.toml"
link_file "${CONFIG_DIR}/tmux/tmux.conf" "${HOME}/.tmux.conf"
link_file "${CONFIG_DIR}/starship/starship.toml" "${HOME}/.config/starship.toml"
link_file "${CONFIG_DIR}/alacritty/alacritty.toml" "${HOME}/.config/alacritty/alacritty.toml"
link_file "${CONFIG_DIR}/nvim/init.lua"   "${HOME}/.config/nvim/init.lua"
link_file "${CONFIG_DIR}/nvim/lua"        "${HOME}/.config/nvim/lua"
link_file "${CONFIG_DIR}/nvim/keymaps.md" "${HOME}/.config/nvim/keymaps.md"
link_file "${CONFIG_DIR}/hammerspoon/init.lua" "${HOME}/.hammerspoon/init.lua"
if [[ -f "${CONFIG_DIR}/gh/config.yml" ]]; then
  link_file "${CONFIG_DIR}/gh/config.yml" "${HOME}/.config/gh/config.yml"
fi

if [[ "${SKIP_BREW}" == false ]] && command -v mise >/dev/null 2>&1; then
  echo "Installing mise-managed tools..."
  mise install
  echo "Enabling pnpm via Corepack..."
  mise exec -- corepack enable pnpm
fi

FISH_BIN="$(command -v fish || true)"
if [[ -n "${FISH_BIN}" && "${SHELL:-}" != "${FISH_BIN}" ]]; then
  if ! grep -qx "${FISH_BIN}" /etc/shells; then
    echo "Adding ${FISH_BIN} to /etc/shells (requires sudo)..."
    echo "${FISH_BIN}" | sudo tee -a /etc/shells >/dev/null
  fi
  echo "Changing default shell to fish..."
  chsh -s "${FISH_BIN}"
fi

echo "macOS standalone setup complete. 🧉"
