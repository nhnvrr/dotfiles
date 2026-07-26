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

  # Plugins are installed explicitly rather than via a symlinked fish_plugins
  # manifest: Fisher REWRITES that file and would replace the symlink with a
  # regular file. Both commands are idempotent.
  if command -v fish >/dev/null 2>&1; then
    echo "Installing fish plugins (fisher + tide)..."
    fish -c 'functions -q fisher; or curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
    fish -c 'fisher install IlanCosman/tide@v6'
    # Seeds Tide's base config, which lives in universal variables.
    # fish/config.fish shadows it afterwards with `set -g`.
    fish -c 'tide configure --auto --style=Lean --prompt_colors="True color" --show_time="24-hour format" --lean_prompt_height="Two lines" --prompt_connection=Disconnected --prompt_connection_andor_frame_color=Lightest --prompt_spacing=Sparse --icons="Many icons" --transient=Yes'
  fi
else
  echo "Skipping Homebrew setup (--skipBrew); only linking configuration."
fi

echo "Configuring git..."
link_file "${CONFIG_DIR}/git/gitconfig"        "${HOME}/.gitconfig"
link_file "${CONFIG_DIR}/git/ignore"           "${HOME}/.config/git/ignore"
link_file "${CONFIG_DIR}/git/allowed_signers"  "${HOME}/.config/git/allowed_signers"

SSH_KEY="${HOME}/.ssh/id_ed25519"
SSH_PUB="${SSH_KEY}.pub"

if [[ ! -f "${SSH_KEY}" ]]; then
  echo "Generating SSH key (ed25519)..."
  mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
  ssh-keygen -t ed25519 -C "$(git config --get user.email)" -f "${SSH_KEY}" -N ""

  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "${SSH_PUB}"
    echo "  ✓ SSH pubkey copied to clipboard."
    echo "  → Add it at https://github.com/settings/ssh/new (auth + signing)"
  fi
fi

# Deliberately OUTSIDE the block above: on a machine where the key already
# exists this still has to run. The grep avoids duplicating the entry.
mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
if ! grep -q "UseKeychain yes" "${HOME}/.ssh/config" 2>/dev/null; then
  echo "Configuring ~/.ssh/config (agent + Keychain)..."
  cat >> "${HOME}/.ssh/config" <<'EOF'

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
# config.fish only: Fisher and Tide WRITE into ~/.config/fish/{functions,
# completions,conf.d}, so symlinking those would dirty the repo with plugins.
link_file "${CONFIG_DIR}/fish/config.fish" "${HOME}/.config/fish/config.fish"
link_file "${CONFIG_DIR}/alacritty/alacritty.toml" "${HOME}/.config/alacritty/alacritty.toml"
# Symlinks from the previous terminal, removed only if they point into this repo.
for stale in "${HOME}/.config/ghostty/config" "${HOME}/.config/ghostty/themes"; do
  if [[ -L "${stale}" && "$(readlink "${stale}")" == "${CONFIG_DIR}"/ghostty/* ]]; then
    rm -f "${stale}"
    echo "  removed stale Ghostty symlink ${stale}"
  fi
done
link_file "${CONFIG_DIR}/mise/config.toml" "${HOME}/.config/mise/config.toml"
link_file "${CONFIG_DIR}/tmux/tmux.conf" "${HOME}/.tmux.conf"
link_file "${CONFIG_DIR}/nvim/init.lua"   "${HOME}/.config/nvim/init.lua"
link_file "${CONFIG_DIR}/hammerspoon/init.lua" "${HOME}/.hammerspoon/init.lua"
# psqlrc writes history to ~/.local/state/psql/history-<db>. psql won't create
# that directory: without it, history fails silently.
mkdir -p "${HOME}/.local/state/psql"
link_file "${CONFIG_DIR}/psql/psqlrc" "${HOME}/.psqlrc"
if [[ -f "${CONFIG_DIR}/gh/config.yml" ]]; then
  link_file "${CONFIG_DIR}/gh/config.yml" "${HOME}/.config/gh/config.yml"
fi

# Orphans from the zsh+starship → fish+tide migration. Removed only if they
# point into this repo, so a hand-written ~/.zshrc stays untouched.
for stale in "${HOME}/.zshrc" "${HOME}/.config/starship.toml"; do
  if [[ -L "${stale}" && "$(readlink "${stale}")" == "${CONFIG_DIR}"/* ]]; then
    rm -f "${stale}"
    echo "  removed stale symlink ${stale}"
  fi
done

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
# The Dock is deliberately left alone: it's a visual preference, set it from
# System Settings. This script only touches what affects working.
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location "${HOME}/Screenshots"
defaults write com.apple.screencapture type -string "png"
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

# chsh rejects shells missing from /etc/shells, so register it first (needs
# sudo). dscl reads the real login shell, not $SHELL.
FISH_BIN="$(command -v fish || true)"
if [[ -n "${FISH_BIN}" ]]; then
  if ! grep -qx "${FISH_BIN}" /etc/shells; then
    echo "Registering ${FISH_BIN} in /etc/shells (sudo required)..."
    echo "${FISH_BIN}" | sudo tee -a /etc/shells >/dev/null
  fi
  LOGIN_SHELL="$(dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}')"
  if [[ "${LOGIN_SHELL}" != "${FISH_BIN}" ]]; then
    echo "Changing login shell to ${FISH_BIN} (chsh will prompt for your password)..."
    chsh -s "${FISH_BIN}"
  fi
else
  echo "  ⚠ fish not found; login shell left as-is. Run without --skipBrew to install it."
fi

echo "macOS standalone setup complete. Happy Coding 🧉"
