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
  if [[ -e "${dst}" && ! -L "${dst}" ]]; then
    local backup="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
    mv "${dst}" "${backup}"
    echo "  backed up ${dst} → ${backup}"
  fi
  ln -sfn "${src}" "${dst}"
}

if [[ -n "${BREW_BIN}" ]]; then
  eval "$("${BREW_BIN}" shellenv)"
elif [[ "${SKIP_BREW}" == false ]]; then
  ensure_brew
  eval "$("${BREW_BIN}" shellenv)"
fi

if [[ "${SKIP_BREW}" == false ]]; then
  echo "Installing Homebrew packages..."
  "${BREW_BIN}" update

  echo "Applying Brewfile..."
  "${BREW_BIN}" bundle --file="${CONFIG_DIR}/Brewfile"
else
  echo "Skipping Homebrew setup (--skipBrew); only linking configuration."
fi

echo "Configuring git..."
export GIT_CONFIG_GLOBAL="${HOME}/.gitconfig"
touch "${GIT_CONFIG_GLOBAL}"
git config --global user.name "Nicolas Navarro"
git config --global user.email "navarropaeznicolas@gmail.com"
git config --global init.defaultBranch "main"
git config --global push.default "tracking"
git config --global push.autoSetupRemote "true"
git config --global pull.rebase "true"
git config --global branch.autosetuprebase "always"
git config --global rerere.enabled "true"
git config --global color.ui "true"
git config --global core.askPass ""
git config --global core.editor "nvim"
git config --global credential.helper "osxkeychain"
git config --global diff.algorithm "histogram"
git config --global merge.conflictstyle "zdiff3"
git config --global github.user "nhnvrr"
git config --global alias.cleanup "!git branch --merged | grep -v '\\*\\|master\\|develop\\|main' | xargs -n 1 -r git branch -d"
git config --global alias.prettylog "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
git config --global alias.root "rev-parse --show-toplevel"

SSH_KEY="${HOME}/.ssh/id_ed25519"
SSH_PUB="${SSH_KEY}.pub"

if [[ ! -f "${SSH_KEY}" ]]; then
  echo "Generating SSH key (ed25519)..."
  mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
  ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "${SSH_KEY}" -N ""

  # Configure ~/.ssh/config so the key is loaded into agent + Keychain on demand.
  if ! grep -q "UseKeychain yes" "${HOME}/.ssh/config" 2>/dev/null; then
    cat >> "${HOME}/.ssh/config" <<'EOF'

Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
    chmod 600 "${HOME}/.ssh/config"
  fi

  ssh-add --apple-use-keychain "${SSH_KEY}" 2>/dev/null || true

  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "${SSH_PUB}"
    echo "  ✓ SSH pubkey copied to clipboard."
    echo "  → Add it at https://github.com/settings/ssh/new (auth + signing)"
  fi
fi

git config --global gpg.format "ssh"
git config --global user.signingkey "${SSH_PUB}"
git config --global commit.gpgsign "true"
git config --global tag.gpgsign "true"

if command -v gh >/dev/null 2>&1 && ! gh auth status >/dev/null 2>&1; then
  echo "  → Run 'gh auth login' to authenticate with GitHub."
fi

echo "Preparing Go workspace..."
mkdir -p "${HOME}/Develop/go/bin"

echo "Linking config files..."
link_file "${CONFIG_DIR}/zsh/zshrc" "${HOME}/.zshrc"
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

# Theme: OneDark (dark-only, sin toggle). Symlink directo al repo → editar
# onedark.toml / onedark.tmux se refleja solo. theme.toml lo importa alacritty.toml;
# theme.tmux lo sourcea tmux.conf.
link_file "${CONFIG_DIR}/alacritty/themes/onedark.toml" "${HOME}/.config/alacritty/theme.toml"
link_file "${CONFIG_DIR}/tmux/onedark.tmux" "${HOME}/.config/tmux/theme.tmux"

if [[ "${SKIP_BREW}" == false ]] && command -v mise >/dev/null 2>&1; then
  echo "Installing mise-managed tools..."
  mise install
  echo "Enabling pnpm via Corepack..."
  mise exec -- corepack enable pnpm
fi

echo "Applying macOS defaults..."
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.dock autohide -bool true
# Sin delay al revelar y animación casi instantánea — autohide usable, no molesto.
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock show-recents -bool false
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location "${HOME}/Screenshots"
defaults write com.apple.screencapture type -string "png"
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

if ! ls "${HOME}/Library/Fonts/"IoskeleyMonoTermNerdFont*.ttf >/dev/null 2>&1; then
  echo "Installing Ioskeley Term Nerd Font..."
  IOSKELEY_TMP="$(mktemp -d)"
  if curl -fsSL -o "${IOSKELEY_TMP}/ioskeley.zip" \
      "https://github.com/ahatem/IoskeleyMono/releases/download/v2.0.0/IoskeleyMono-Term-NerdFont.zip"; then
    unzip -q -o "${IOSKELEY_TMP}/ioskeley.zip" -d "${IOSKELEY_TMP}/extract"
    find "${IOSKELEY_TMP}/extract" -name "*.ttf" -exec cp {} "${HOME}/Library/Fonts/" \;
  else
    echo "  ⚠ font download failed (continuing). Re-run install.sh to retry."
  fi
  rm -rf "${IOSKELEY_TMP}"
fi

LOGIN_SHELL="$(dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}')"
if [[ "${LOGIN_SHELL}" != "/bin/zsh" ]]; then
  echo "Changing login shell to /bin/zsh (chsh will prompt for your password)..."
  chsh -s /bin/zsh
fi

echo "macOS standalone setup complete. Happy Coding 🧉"
