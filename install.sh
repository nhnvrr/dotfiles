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

# vscode-js-debug is the DAP adapter for Node and TypeScript. It is neither a
# Homebrew formula nor a published npm package, so the release tarball is
# vendored by hand.
#
# The version is pinned rather than tracking `latest`: nvim/lua/config/debug.lua
# hardcodes src/dapDebugServer.js, which is a path inside this tarball's layout,
# not a stable public interface.
#
# The guard compares a stamp file rather than testing for the entry point: the
# tarball carries no readable version of its own, so "the file is there" would
# leave whatever build a previous setup happened to drop — and the pin above
# would then describe a version that is not on disk.
JS_DEBUG_VERSION="1.105.0"
JS_DEBUG_DIR="${HOME}/.local/share/nvim/js-debug"
JS_DEBUG_STAMP="${JS_DEBUG_DIR}/.dotfiles-version"
if [[ "$(cat "${JS_DEBUG_STAMP}" 2>/dev/null || true)" != "${JS_DEBUG_VERSION}" ]]; then
  echo "Installing vscode-js-debug ${JS_DEBUG_VERSION}..."
  JS_DEBUG_TMP="$(mktemp -d)"
  # Download, unpack and probe all inside the condition. Under `set -e` a
  # truncated tarball or a changed layout would otherwise abort install.sh
  # outright — and this block runs before any symlink is created, so the machine
  # would be left with no configuration at all over a failed optional download.
  # The tarball unpacks into a top-level js-debug/ directory.
  if curl -fsSL \
    "https://github.com/microsoft/vscode-js-debug/releases/download/v${JS_DEBUG_VERSION}/js-debug-dap-v${JS_DEBUG_VERSION}.tar.gz" \
    -o "${JS_DEBUG_TMP}/js-debug.tar.gz" &&
    tar -xzf "${JS_DEBUG_TMP}/js-debug.tar.gz" -C "${JS_DEBUG_TMP}" &&
    [[ -f "${JS_DEBUG_TMP}/js-debug/src/dapDebugServer.js" ]]; then
    mkdir -p "$(dirname "${JS_DEBUG_DIR}")"
    rm -rf "${JS_DEBUG_DIR}"
    mv "${JS_DEBUG_TMP}/js-debug" "${JS_DEBUG_DIR}"
    echo "${JS_DEBUG_VERSION}" > "${JS_DEBUG_STAMP}"
  else
    # Not fatal: nvim only registers the Node adapter when the file exists, so
    # this costs Node debugging and nothing else.
    echo "  ! Could not install vscode-js-debug; Node/TS debugging will be unavailable."
  fi
  rm -rf "${JS_DEBUG_TMP}"
fi

echo "Linking config files..."
link_file "${CONFIG_DIR}/zsh/zshenv" "${HOME}/.zshenv"
link_file "${CONFIG_DIR}/zsh/zshrc" "${HOME}/.zshrc"
link_file "${CONFIG_DIR}/zsh/completions/_aws" "${HOME}/.config/zsh/completions/_aws"
# zsh won't create it and history is dropped silently without it, same as psql.
mkdir -p "${HOME}/.local/state/zsh" "${HOME}/.cache/zsh"
link_file "${CONFIG_DIR}/mise/config.toml" "${HOME}/.config/mise/config.toml"
# Only read because zsh/zshenv exports EZA_CONFIG_DIR to this path; eza's own
# default on macOS is ~/Library/Application Support/eza.
link_file "${CONFIG_DIR}/eza/theme.yml" "${HOME}/.config/eza/theme.yml"
# The whole directory, because the config is init.lua plus lua/config/*.lua and
# `require` resolves those through runtimepath — a symlink to init.lua alone
# leaves every module unreachable.
#
# The previous revision linked the single file, so ~/.config/nvim is a real
# directory holding that symlink. It has to go before the directory symlink can
# be created, and only when it holds nothing but what this script put there.
# Anything else is the user's, and link_file backs it up rather than deleting.
#
# nvim-pack-lock.json is the exception worth carrying across: vim.pack writes it
# to stdpath('config'), so after this switch it lives inside the repo and gets
# version-controlled, which is what :h vim.pack recommends. Moving it preserves
# the pinned plugin revisions instead of resolving them again.
NVIM_DST="${HOME}/.config/nvim"
if [[ ! -L "${NVIM_DST}" && -L "${NVIM_DST}/init.lua" ]] &&
  [[ "$(readlink "${NVIM_DST}/init.lua")" == "${CONFIG_DIR}/nvim/init.lua" ]]; then
  rm "${NVIM_DST}/init.lua"
  if [[ -f "${NVIM_DST}/nvim-pack-lock.json" && ! -f "${CONFIG_DIR}/nvim/nvim-pack-lock.json" ]]; then
    mv "${NVIM_DST}/nvim-pack-lock.json" "${CONFIG_DIR}/nvim/nvim-pack-lock.json"
    echo "  moved nvim-pack-lock.json into the repo (it is version-controlled now)"
  fi
  # Only if nothing else is left; a non-empty directory falls through to
  # link_file, which backs it up.
  rmdir "${NVIM_DST}" 2>/dev/null || true
fi
link_file "${CONFIG_DIR}/nvim" "${NVIM_DST}"
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
# following alacritty/alacritty.toml for free. Expect btop to churn the file whenever a
# setting is changed from its UI.
link_file "${CONFIG_DIR}/alacritty/alacritty.toml" "${HOME}/.config/alacritty/alacritty.toml"
link_file "${CONFIG_DIR}/btop/btop.conf" "${HOME}/.config/btop/btop.conf"
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

# /bin/zsh is macOS's default and is already in /etc/shells, so there is nothing
# to register and no sudo — this only matters on a machine left on bash or fish.
# dscl reads the real login shell, not $SHELL.
ZSH_BIN=/bin/zsh
LOGIN_SHELL="$(dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}')"
if [[ "${LOGIN_SHELL}" != "${ZSH_BIN}" ]]; then
  echo "Changing login shell to ${ZSH_BIN} (chsh will prompt for your password)..."
  chsh -s "${ZSH_BIN}"
fi

echo "macOS standalone setup complete. Happy Coding 🧉"
