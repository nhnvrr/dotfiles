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
link_file "${CONFIG_DIR}/fish/config.fish"       "${HOME}/.config/fish/config.fish"
link_file "${CONFIG_DIR}/fish/conf.d/00-env.fish" "${HOME}/.config/fish/conf.d/00-env.fish"
link_file "${CONFIG_DIR}/fish/conf.d/10-colors.fish" "${HOME}/.config/fish/conf.d/10-colors.fish"
link_file "${CONFIG_DIR}/fish/completions/aws.fish" "${HOME}/.config/fish/completions/aws.fish"
link_file "${CONFIG_DIR}/starship/starship.toml" "${HOME}/.config/starship.toml"
link_file "${CONFIG_DIR}/ghostty/config" "${HOME}/.config/ghostty/config"
link_file "${CONFIG_DIR}/mise/config.toml" "${HOME}/.config/mise/config.toml"
# Only read because config.fish exports EZA_CONFIG_DIR to this path; eza's own
# default on macOS is ~/Library/Application Support/eza.
link_file "${CONFIG_DIR}/eza/theme.yml" "${HOME}/.config/eza/theme.yml"
# Older revisions linked this entire directory. Remove only that known symlink
# before switching to the single-file layout; local directories stay untouched.
if [[ -L "${HOME}/.config/nvim" && "$(readlink "${HOME}/.config/nvim")" == "${CONFIG_DIR}/nvim" ]]; then
  unlink "${HOME}/.config/nvim"
fi
link_file "${CONFIG_DIR}/nvim/init.lua" "${HOME}/.config/nvim/init.lua"
# Only config.toml and not the directory: herdr keeps its sockets, logs and
# workspace state in the same folder and writes to them at runtime.
link_file "${CONFIG_DIR}/herdr/config.toml" "${HOME}/.config/herdr/config.toml"
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

# chsh rejects shells missing from /etc/shells, and a login shell that isn't
# there locks you out of new terminals — hence the existence check before the
# chsh. dscl reads the real login shell, not $SHELL.
FISH_BIN="$(command -v fish || true)"
if [[ -z "${FISH_BIN}" ]]; then
  echo "fish not found; leaving the login shell alone. Run './install.sh' again after 'brew bundle'."
else
  if ! grep -qx "${FISH_BIN}" /etc/shells; then
    echo "Registering ${FISH_BIN} in /etc/shells (sudo required)..."
    echo "${FISH_BIN}" | sudo tee -a /etc/shells >/dev/null
  fi
  LOGIN_SHELL="$(dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}')"
  if [[ "${LOGIN_SHELL}" != "${FISH_BIN}" ]]; then
    echo "Changing login shell to ${FISH_BIN} (chsh will prompt for your password)..."
    chsh -s "${FISH_BIN}"
  fi
fi

echo "macOS standalone setup complete. Happy Coding 🧉"
