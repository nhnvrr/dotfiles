#!/usr/bin/env bash

set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || {
  echo "This setup is only supported on macOS."
  exit 1
}

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
    local backup
    backup="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
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
link_file "${CONFIG_DIR}/git/gitconfig" "${HOME}/.gitconfig"
link_file "${CONFIG_DIR}/git/ignore" "${HOME}/.config/git/ignore"
link_file "${CONFIG_DIR}/git/allowed_signers" "${HOME}/.config/git/allowed_signers"

SSH_KEY="${HOME}/.ssh/id_ed25519"
SSH_PUB="${SSH_KEY}.pub"

if [[ ! -f "${SSH_KEY}" ]]; then
  echo "Generating SSH key (ed25519)..."
  mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
  ssh-keygen -t ed25519 -C "$(git config --get user.email)" -f "${SSH_KEY}" -N ""

  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy <"${SSH_PUB}"
    echo "  ✓ SSH pubkey copied to clipboard."
    echo "  → Add it at https://github.com/settings/ssh/new (auth + signing)"
  fi
fi

# Deliberately OUTSIDE the block above: on a machine where the key already
# exists this still has to run. The marker avoids duplicating the entry.
mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
# Matched against a sentinel this block owns, not against `UseKeychain yes`:
# that string is legal inside any per-host block, so grepping the whole file
# reports success while the `Host *` defaults were never written.
SSH_MARKER="# managed by dotfiles"
if ! grep -qF "${SSH_MARKER}" "${HOME}/.ssh/config" 2>/dev/null; then
  echo "Configuring ~/.ssh/config (agent + Keychain)..."
  cat >>"${HOME}/.ssh/config" <<'EOF'

# managed by dotfiles
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
  chmod 600 "${HOME}/.ssh/config"
fi
ssh-add --apple-use-keychain "${SSH_KEY}" 2>/dev/null || true

if command -v gh >/dev/null 2>&1 && ! gh auth status >/dev/null 2>&1; then
  echo "  → Run 'gh auth login' to authenticate with GitHub."
fi

echo "Preparing Go workspace..."
mkdir -p "${HOME}/Develop/go/bin"

echo "Linking config files..."
link_file "${CONFIG_DIR}/fish" "${HOME}/.config/fish"
link_file "${CONFIG_DIR}/nvim" "${HOME}/.config/nvim"
link_file "${CONFIG_DIR}/mise/config.toml" "${HOME}/.config/mise/config.toml"
# Only config.toml and not the directory: herdr keeps its sockets, logs and
# workspace state in the same folder and writes to them at runtime.
link_file "${CONFIG_DIR}/herdr/config.toml" "${HOME}/.config/herdr/config.toml"
# The notification sounds, next to the config that names them by relative path.
# See the comment on [ui.sound]: config.toml is a symlink, so the relative path
# resolves either here or in the repo depending on whether herdr calls realpath
# first, and linking these makes both readings land on the same file.
link_file "${CONFIG_DIR}/herdr/sounds/done.mp3" "${HOME}/.config/herdr/sounds/done.mp3"
link_file "${CONFIG_DIR}/herdr/sounds/request.mp3" "${HOME}/.config/herdr/sounds/request.mp3"
# btop rewrites this file on exit, comments and all, so the reason it is here
# cannot live inside it: color_theme = "TTY" makes btop draw from the terminal's
# sixteen ANSI slots instead of a theme file of its own, which is what keeps it
# following ghostty/config for free. Expect btop to churn the file whenever a
# setting is changed from its UI.
link_file "${CONFIG_DIR}/ghostty/config" "${HOME}/.config/ghostty/config"
link_file "${CONFIG_DIR}/btop/btop.conf" "${HOME}/.config/btop/btop.conf"
# The XDG path, which tmux has read since 3.1, and not ~/.tmux.conf — still
# honoured, but only as a fallback and only when this file is absent. An older
# ~/.tmux.conf left over from a previous machine is not touched by this and
# silently stops being read, which is the confusing half of the move.
# The file and not the directory: a plugin manager would clone into the same
# folder, and linking the directory would drag those clones into the repo.
link_file "${CONFIG_DIR}/tmux/tmux.conf" "${HOME}/.config/tmux/tmux.conf"
# Same trap as psql: history-file is dropped silently without the first, and
# resurrect saves nowhere without the second. tmux creates neither.
mkdir -p "${HOME}/.local/state/tmux/resurrect" "${HOME}/.local/share/tmux/plugins"
# Only init.lua: ~/.hammerspoon/Spoons is downloaded state, not config.
link_file "${CONFIG_DIR}/hammerspoon/init.lua" "${HOME}/.hammerspoon/init.lua"
# psql won't create this directory and history fails silently without it.
mkdir -p "${HOME}/.local/state/psql"
link_file "${CONFIG_DIR}/psql/psqlrc" "${HOME}/.psqlrc"
# Same trap: REDISCLI_HISTFILE points inside it, and redis-cli won't mkdir.
mkdir -p "${HOME}/.local/state/redis"
if [[ -f "${CONFIG_DIR}/gh/config.yml" ]]; then
  link_file "${CONFIG_DIR}/gh/config.yml" "${HOME}/.config/gh/config.yml"
fi

# Without this the plugins only arrive when someone presses prefix + I by hand,
# and continuum silently restores nothing until they do.
TPM_INSTALL="$("${BREW_BIN:-brew}" --prefix 2>/dev/null)/opt/tpm/share/tpm/bin/install_plugins"
if [[ "${SKIP_BREW}" == false && -x "${TPM_INSTALL}" ]]; then
  echo "Installing tmux plugins..."
  TMUX_PLUGIN_MANAGER_PATH="${HOME}/.local/share/tmux/plugins" "${TPM_INSTALL}"
fi

BOBTHEFISH="${HOME}/.local/share/fish/bobthefish"
if [[ ! -d "${BOBTHEFISH}" ]]; then
  echo "Installing bobthefish..."
  git clone -q --depth 1 https://github.com/oh-my-fish/theme-bobthefish "${BOBTHEFISH}"
fi

if [[ "${SKIP_BREW}" == false ]] && command -v mise >/dev/null 2>&1; then
  echo "Installing mise-managed tools..."
  mise install
fi

echo "Applying macOS defaults..."
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location "${HOME}/Screenshots"
defaults write com.apple.screencapture type -string "png"
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

# chsh refuses a shell missing from /etc/shells; registering it is the one sudo.
# dscl reads the real login shell, not $SHELL.
FISH_BIN="$(dirname "${BREW_BIN}")/fish"
if [[ -x "${FISH_BIN}" ]]; then
  if ! grep -qxF "${FISH_BIN}" /etc/shells; then
    echo "Registering ${FISH_BIN} in /etc/shells (sudo)..."
    echo "${FISH_BIN}" | sudo tee -a /etc/shells >/dev/null
  fi
  LOGIN_SHELL="$(dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}')"
  if [[ "${LOGIN_SHELL}" != "${FISH_BIN}" ]]; then
    echo "Changing login shell to ${FISH_BIN} (chsh will prompt for your password)..."
    chsh -s "${FISH_BIN}"
  fi
fi

echo "macOS standalone setup complete. Happy Coding 🧉"
