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

  # A hand-installed copy of the font makes `brew bundle` fail; moved aside, not deleted.
  FONT_CASK="font-ioskeley-mono-term-nerd-font"
  if ! "${BREW_BIN}" list --cask "${FONT_CASK}" >/dev/null 2>&1; then
    for f in "${HOME}"/Library/Fonts/IoskeleyMonoTermNerdFontMono-*.ttf; do
      [[ -e "${f}" ]] || continue
      mkdir -p "${HOME}/Library/Fonts/pre-brew"
      mv "${f}" "${HOME}/Library/Fonts/pre-brew/"
      echo "  moved hand-installed $(basename "${f}") to ~/Library/Fonts/pre-brew/"
    done
  fi

  echo "Applying Brewfile..."
  "${BREW_BIN}" bundle --file="${CONFIG_DIR}/Brewfile"
else
  echo "Skipping Homebrew setup (--skipBrew); only linking configuration."
fi

SSH_KEY="${HOME}/.ssh/id_ed25519"
SSH_PUB="${SSH_KEY}.pub"

if [[ ! -f "${SSH_KEY}" ]]; then
  echo "Generating SSH key (ed25519)..."
  mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
  SSH_COMMENT="$(git config --get user.email || true)"
  ssh-keygen -t ed25519 -C "${SSH_COMMENT:-$(whoami)@$(hostname -s)}" -f "${SSH_KEY}" -N ""

  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy <"${SSH_PUB}"
    echo "  ✓ SSH pubkey copied to clipboard."
    echo "  → Add it at https://github.com/settings/ssh/new (auth + signing)"
  fi
fi

mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
# Grep for this sentinel, not for `UseKeychain yes`: that is legal inside any Host block.
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
link_file "${CONFIG_DIR}/zsh/zshenv" "${HOME}/.zshenv"
link_file "${CONFIG_DIR}/zsh/zshrc" "${HOME}/.zshrc"
link_file "${CONFIG_DIR}/zsh/functions" "${HOME}/.config/zsh/functions"
link_file "${CONFIG_DIR}/starship/starship.toml" "${HOME}/.config/starship.toml"
mkdir -p "${HOME}/.local/state/zsh" "${HOME}/.cache/zsh"
# compinit refuses the zsh-completions symlinks while share/ is group-writable.
chmod go-w /opt/homebrew/share
link_file "${CONFIG_DIR}/ghostty" "${HOME}/.config/ghostty"
VSCODE_USER="${HOME}/Library/Application Support/Code/User"
link_file "${CONFIG_DIR}/vscode/settings.json" "${VSCODE_USER}/settings.json"
link_file "${CONFIG_DIR}/vscode/keybindings.json" "${VSCODE_USER}/keybindings.json"
VSCODE_THEME="${HOME}/.vscode/extensions/nhnvrr.mate-theme-0.0.1"
# A vsix install is a plain copy; a .bak of it beside the link would load twice.
[[ -d "${VSCODE_THEME}" && ! -L "${VSCODE_THEME}" ]] && rm -rf "${VSCODE_THEME}"
link_file "${CONFIG_DIR}/vscode/extensions/mate" "${VSCODE_THEME}"
link_file "${CONFIG_DIR}/vim/vimrc" "${HOME}/.vim/vimrc"
link_file "${CONFIG_DIR}/vim/colors" "${HOME}/.vim/colors"
link_file "${CONFIG_DIR}/hammerspoon/init.lua" "${HOME}/.hammerspoon/init.lua"
link_file "${CONFIG_DIR}/hammerspoon/mate" "${HOME}/.hammerspoon/mate"
link_file "${CONFIG_DIR}/mise/config.toml" "${HOME}/.config/mise/config.toml"
link_file "${CONFIG_DIR}/btop/btop.conf" "${HOME}/.config/btop/btop.conf"
link_file "${CONFIG_DIR}/btop/themes/mate.theme" "${HOME}/.config/btop/themes/mate.theme"
link_file "${CONFIG_DIR}/tmux/tmux.conf" "${HOME}/.config/tmux/tmux.conf"
link_file "${CONFIG_DIR}/claude/base/statusline.sh" "${HOME}/.claude/statusline.sh"
mkdir -p "${HOME}/.local/state/tmux"
mkdir -p "${HOME}/.local/state/redis"
if [[ -f "${CONFIG_DIR}/gh/config.yml" ]]; then
  link_file "${CONFIG_DIR}/gh/config.yml" "${HOME}/.config/gh/config.yml"
fi

if [[ "${SKIP_BREW}" == false ]] && command -v mise >/dev/null 2>&1; then
  echo "Installing mise-managed tools..."
  mise install
fi

NVM_SH="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm/nvm.sh"
export NVM_DIR="${HOME}/.nvm"
mkdir -p "${NVM_DIR}"
if [[ -r "${NVM_SH}" && ! -r "${NVM_DIR}/alias/default" ]]; then
  echo "Installing node 24 via nvm..."
    # nvm.sh reads unset variables; set -u would kill the run inside it.
  set +u
  # shellcheck disable=SC1090
  source "${NVM_SH}" --no-use
  nvm install 24
  nvm alias default 24
  set -u
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

if command -v duti >/dev/null 2>&1 && open -Ra "Visual Studio Code" 2>/dev/null; then
    # Until VS Code is registered with LaunchServices, .toml/.ini/.cfg are dynamic UTIs and duti fails.
  VSCODE_APP="$(mdfind "kMDItemCFBundleIdentifier == 'com.microsoft.VSCode'" 2>/dev/null | head -1)"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "${VSCODE_APP:-/Applications/Visual Studio Code.app}" >/dev/null 2>&1 || true
  duti -s com.microsoft.VSCode public.plain-text all
  duti -s com.microsoft.VSCode public.json all
  duti -s com.microsoft.VSCode public.yaml all
  duti -s com.microsoft.VSCode net.daringfireball.markdown all
  for ext in toml ini cfg env tfvars; do
    duti -s com.microsoft.VSCode ".${ext}" all 2>/dev/null \
      || echo "  → .${ext}: no app has registered this extension yet; open one in VS Code and rerun."
  done
fi
REX_DOMAIN="com.superlogical.rex"
defaults write "${REX_DOMAIN}" Workspace.customThemes -string "$(cat "${CONFIG_DIR}/rex/themes.json")"
defaults write "${REX_DOMAIN}" Workspace.darkThemeID -string "custom-8CB97BC0-2529-4DDA-9CE5-4B87204CFBB9"
defaults write "${REX_DOMAIN}" Workspace.lightThemeID -string "custom-BA5C3648-D51E-4CE1-989C-96B1F9FFDDCB"
defaults write "${REX_DOMAIN}" Workspace.interfaceStyle -string "useTheme"
defaults write "${REX_DOMAIN}" Workspace.terminalFontName -string "IoskeleyMonoTerm Nerd Font Mono"
defaults write "${REX_DOMAIN}" Workspace.terminalFontPointSize -float 14
defaults write "${REX_DOMAIN}" Workspace.terminalFontSmoothing -bool false
defaults write "${REX_DOMAIN}" Workspace.terminalUseThemePalette -bool false
defaults write "${REX_DOMAIN}" Workspace.terminalUsesDisplayP3 -bool false
defaults write "${REX_DOMAIN}" Workspace.terminalCursorStyle -string "bar"
defaults write "${REX_DOMAIN}" Workspace.terminalCursorBlinkUsesCustomInterval -bool false
defaults write "${REX_DOMAIN}" Workspace.terminalCopyOnSelect -bool true
defaults write "${REX_DOMAIN}" Workspace.sidebarPosition -string "left"
defaults write "${REX_DOMAIN}" Workspace.tabStyle -string "horizontal"
defaults write "${REX_DOMAIN}" Workspace.tabsFillAvailableSpace -bool false
defaults write "${REX_DOMAIN}" Workspace.tabIconCount -int 4
defaults write "${REX_DOMAIN}" Workspace.tabIconTintMode -string "off"
defaults write "${REX_DOMAIN}" Workspace.showsPaneHeaders -bool true
defaults write "${REX_DOMAIN}" Workspace.showsProgramStatusInTabs -bool true
defaults write "${REX_DOMAIN}" Workspace.paneDensity -string "comfortable"
defaults write "${REX_DOMAIN}" Workspace.fadesInactivePanes -bool true
defaults write "${REX_DOMAIN}" Workspace.inactivePaneFadeMode -string "both"
defaults write "${REX_DOMAIN}" Workspace.usesPaneGlass -bool false
defaults write "${REX_DOMAIN}" Workspace.usesStandardInactiveWindowPaneStyles -bool true
defaults write "${REX_DOMAIN}" Workspace.balancesSplitsOnCreation -bool false
defaults write "${REX_DOMAIN}" Workspace.appIcon -string "default"
link_file "${CONFIG_DIR}/rex/shortcuts.json" "${HOME}/Library/Application Support/${REX_DOMAIN}/Shortcuts/shortcuts.json"

# Rebuilt from scratch on every run; an app that is not installed is skipped.
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 64
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 96
defaults write com.apple.dock orientation -string "bottom"
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool false
defaults delete com.apple.dock persistent-apps 2>/dev/null || true
defaults delete com.apple.dock persistent-others 2>/dev/null || true
for app in "Visual Studio Code" "Claude" "Docker" "Rex Beta" "TablePlus"; do
  [[ -d "/Applications/${app}.app" ]] || continue
  defaults write com.apple.dock persistent-apps -array-add \
    "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/${app}.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict><key>tile-type</key><string>file-tile</string></dict>"
done
defaults write com.apple.dock persistent-others -array-add \
  "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file://${HOME}/Downloads/</string><key>_CFURLStringType</key><integer>15</integer></dict><key>arrangement</key><integer>2</integer><key>displayas</key><integer>0</integer><key>showas</key><integer>0</integer></dict><key>tile-type</key><string>directory-tile</string></dict>"
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

SHELL_BIN="/bin/zsh"
LOGIN_SHELL="$(dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}')"
if [[ "${LOGIN_SHELL}" != "${SHELL_BIN}" ]]; then
  echo "Changing login shell to ${SHELL_BIN} (chsh will prompt for your password)..."
  chsh -s "${SHELL_BIN}" || echo "chsh needs an interactive password; run it yourself."
fi

echo "macOS standalone setup complete. Happy Coding 🧉"
