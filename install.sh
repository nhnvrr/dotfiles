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
link_file "${CONFIG_DIR}/ghostty" "${HOME}/.config/ghostty"
# Settings come from VS Code's Settings Sync; only the theme lives here. The
# folder name must match the entry in ~/.vscode/extensions/extensions.json.
VSCODE_THEME="${HOME}/.vscode/extensions/nhnvrr.mate-theme-0.0.1"
# A vsix install is a plain copy; a .bak of it beside the link would load twice.
[[ -d "${VSCODE_THEME}" && ! -L "${VSCODE_THEME}" ]] && rm -rf "${VSCODE_THEME}"
link_file "${CONFIG_DIR}/vscode/extensions/mate" "${VSCODE_THEME}"
# Only these two: ~/.vim also holds undo/ and pack/.
link_file "${CONFIG_DIR}/vim/vimrc" "${HOME}/.vim/vimrc"
link_file "${CONFIG_DIR}/vim/colors" "${HOME}/.vim/colors"
VIM_LSP="${HOME}/.vim/pack/plugins/start/lsp"
if [[ -d "${VIM_LSP}/.git" ]]; then
  git -C "${VIM_LSP}" pull --ff-only --quiet
else
  git clone --depth 1 --quiet https://github.com/yegappan/lsp "${VIM_LSP}"
fi
# Files, not ~/.hammerspoon: Spoons/ lives there and is downloaded state.
link_file "${CONFIG_DIR}/hammerspoon/init.lua" "${HOME}/.hammerspoon/init.lua"
link_file "${CONFIG_DIR}/hammerspoon/mate" "${HOME}/.hammerspoon/mate"
link_file "${CONFIG_DIR}/mise/config.toml" "${HOME}/.config/mise/config.toml"
link_file "${CONFIG_DIR}/btop/btop.conf" "${HOME}/.config/btop/btop.conf"
link_file "${CONFIG_DIR}/btop/themes/mate.theme" "${HOME}/.config/btop/themes/mate.theme"
link_file "${CONFIG_DIR}/tmux/tmux.conf" "${HOME}/.config/tmux/tmux.conf"
# history-file is dropped silently without this directory.
mkdir -p "${HOME}/.local/state/tmux"
# REDISCLI_HISTFILE points inside this one, and redis-cli won't mkdir.
mkdir -p "${HOME}/.local/state/redis"
if [[ -f "${CONFIG_DIR}/gh/config.yml" ]]; then
  link_file "${CONFIG_DIR}/gh/config.yml" "${HOME}/.config/gh/config.yml"
fi

if [[ "${SKIP_BREW}" == false ]] && command -v mise >/dev/null 2>&1; then
  echo "Installing mise-managed tools..."
  mise install
fi

# No terminal font here, and none in the Brewfile either: the font-ioskeley-mono
# cask ships only the Normal build, with no Term cut. It is a manual install, see
# the README; the face is named in ghostty/config.

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
# Guarded on the app: duti fails on an unknown bundle id and set -e would stop here.
if command -v duti >/dev/null 2>&1 && open -Ra "Visual Studio Code" 2>/dev/null; then
  duti -s com.microsoft.VSCode public.json all
  duti -s com.microsoft.VSCode public.yaml all
  for ext in toml ini cfg; do
    duti -s com.microsoft.VSCode ".${ext}" all
  done
  # No browser line here on purpose. macOS 27 ignores duti for http/https —
  # error -50 on the schemes, silence on public.html — because only the browser
  # itself may ask for the handler; setting it is a click.
fi
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

# Homebrew's fish is not in /etc/shells, and chsh refuses a shell that is not.
# dscl reads the real login shell, not $SHELL.
SHELL_BIN="${HOMEBREW_PREFIX:-/opt/homebrew}/bin/fish"
if [[ -x "${SHELL_BIN}" ]] && ! grep -qxF "${SHELL_BIN}" /etc/shells; then
  echo "Adding ${SHELL_BIN} to /etc/shells (sudo)..."
  echo "${SHELL_BIN}" | sudo tee -a /etc/shells >/dev/null
fi
LOGIN_SHELL="$(dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}')"
if [[ "${LOGIN_SHELL}" != "${SHELL_BIN}" ]]; then
  echo "Changing login shell to ${SHELL_BIN} (chsh will prompt for your password)..."
  chsh -s "${SHELL_BIN}" || echo "chsh needs an interactive password; run it yourself."
fi

echo "macOS standalone setup complete. Happy Coding 🧉"
