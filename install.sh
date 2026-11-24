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

echo "Installing the bobthefish fish prompt..."
# No plugin manager: a pinned clone that config.fish adds to fish_function_path.
BOB_DIR="${HOME}/.local/share/bobthefish"
BOB_REV="72a89d424644d087c182843a48fbf0a43c796f31"
[[ -d "${BOB_DIR}/.git" ]] || git clone -q https://github.com/oh-my-fish/theme-bobthefish "${BOB_DIR}"
git -C "${BOB_DIR}" fetch -q origin && git -C "${BOB_DIR}" checkout -q "${BOB_REV}"

echo "Linking config files..."
link_file "${CONFIG_DIR}/zsh/zshenv" "${HOME}/.zshenv"
link_file "${CONFIG_DIR}/zsh/zshrc" "${HOME}/.zshrc"
link_file "${CONFIG_DIR}/zsh/functions" "${HOME}/.config/zsh/functions"
link_file "${CONFIG_DIR}/fish/config.fish" "${HOME}/.config/fish/config.fish"
# Not the whole dir: fish writes fish_variables into ~/.config/fish.
link_file "${CONFIG_DIR}/fish/functions" "${HOME}/.config/fish/functions"
# Not the whole dir: nu writes its history and plugin registry there.
link_file "${CONFIG_DIR}/nushell/env.nu" "${HOME}/Library/Application Support/nushell/env.nu"
link_file "${CONFIG_DIR}/nushell/config.nu" "${HOME}/Library/Application Support/nushell/config.nu"
link_file "${CONFIG_DIR}/nushell/autoload" "${HOME}/Library/Application Support/nushell/autoload"
link_file "${CONFIG_DIR}/fish/conf.d/mise-activate.fish" "${HOME}/.config/fish/conf.d/mise-activate.fish"
link_file "${CONFIG_DIR}/starship/starship.toml" "${HOME}/.config/starship.toml"
mkdir -p "${HOME}/.local/state/zsh" "${HOME}/.cache/zsh" "${HOME}/.cache/fish"
# compinit refuses the zsh-completions symlinks while share/ is group-writable.
chmod go-w /opt/homebrew/share
link_file "${CONFIG_DIR}/ghostty" "${HOME}/.config/ghostty"
VSCODE_USER="${HOME}/Library/Application Support/Code/User"
link_file "${CONFIG_DIR}/vscode/settings.json" "${VSCODE_USER}/settings.json"
link_file "${CONFIG_DIR}/vscode/keybindings.json" "${VSCODE_USER}/keybindings.json"
link_file "${CONFIG_DIR}/vim/vimrc" "${HOME}/.vim/vimrc"
link_file "${CONFIG_DIR}/vim/colors" "${HOME}/.vim/colors"
link_file "${CONFIG_DIR}/nvim" "${HOME}/.config/nvim"
link_file "${CONFIG_DIR}/mise/config.toml" "${HOME}/.config/mise/config.toml"
link_file "${CONFIG_DIR}/btop/btop.conf" "${HOME}/.config/btop/btop.conf"
link_file "${CONFIG_DIR}/tmux/tmux.conf" "${HOME}/.config/tmux/tmux.conf"
# Not the whole dir: pgcli writes its history and log into ~/.config/pgcli.
link_file "${CONFIG_DIR}/pgcli/config" "${HOME}/.config/pgcli/config"
link_file "${CONFIG_DIR}/pgcli/config-light" "${HOME}/.config/pgcli/config-light"
link_file "${CONFIG_DIR}/lazygit/config.yml" "${HOME}/.config/lazygit/config.yml"
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

echo "Rebuilding the Dock..."
defaults write com.apple.dock autohide -bool false
defaults write com.apple.dock magnification -bool false
defaults write com.apple.dock show-recents -bool false

dock_url() { # file URL with spaces escaped; the Dock ignores entries with raw spaces
  printf 'file://%s/' "${1// /%20}"
}
dock_app() {
  [[ -d "$1" ]] || { echo "  → $1 not installed; left out of the Dock."; return 0; }
  defaults write com.apple.dock persistent-apps -array-add \
    "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$(dock_url "$1")</string><key>_CFURLStringType</key><integer>15</integer></dict></dict></dict>"
}
dock_folder() {
  defaults write com.apple.dock persistent-others -array-add \
    "<dict><key>tile-type</key><string>directory-tile</string><key>tile-data</key><dict><key>arrangement</key><integer>2</integer><key>displayas</key><integer>0</integer><key>showas</key><integer>1</integer><key>file-type</key><integer>2</integer><key>file-data</key><dict><key>_CFURLString</key><string>$(dock_url "$1")</string><key>_CFURLStringType</key><integer>15</integer></dict></dict></dict>"
}

defaults write com.apple.dock persistent-apps -array
for app in \
  "/System/Applications/Apps.app" \
  "/Applications/Slack.app" \
  "/Applications/Google Chrome.app" \
  "/Applications/Rex Beta.app" \
  "/Applications/Docker.app" \
  "/Applications/Claude.app" \
  "/Applications/Visual Studio Code.app" \
  "/System/Applications/Notes.app" \
  "/System/Applications/Music.app" \
  "/System/Applications/Calculator.app"; do
  dock_app "$app"
done
defaults write com.apple.dock persistent-others -array
dock_folder "${HOME}/Downloads"
dock_folder "${HOME}/Documents"
killall Dock

if command -v duti >/dev/null 2>&1 && open -Ra "Visual Studio Code" 2>/dev/null; then
    # Until VS Code is registered with LaunchServices, .toml/.ini/.cfg are dynamic UTIs and duti fails.
  VSCODE_APP="$(mdfind "kMDItemCFBundleIdentifier == 'com.microsoft.VSCode'" 2>/dev/null | head -1)"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "${VSCODE_APP:-/Applications/Visual Studio Code.app}" >/dev/null 2>&1 || true
  duti -s com.microsoft.VSCode public.plain-text all
  duti -s com.microsoft.VSCode public.json all
  duti -s com.microsoft.VSCode public.yaml all
  duti -s com.microsoft.VSCode net.daringfireball.markdown all
  duti -s com.microsoft.VSCode public.comma-separated-values-text all
  duti -s com.microsoft.VSCode com.netscape.javascript-source all
  for ext in toml ini cfg config env tf tfvars js mjs csv; do
    duti -s com.microsoft.VSCode ".${ext}" all 2>/dev/null \
      || echo "  → .${ext}: no app has registered this extension yet; open one in VS Code and rerun."
  done
fi
REX_DOMAIN="com.superlogical.rex"
defaults write "${REX_DOMAIN}" Workspace.terminalFontName -string "JetBrains Mono"
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

killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

SHELL_BIN="/opt/homebrew/bin/fish"
# chsh refuses a shell that is not listed in /etc/shells.
grep -qx "${SHELL_BIN}" /etc/shells || echo "${SHELL_BIN}" | sudo tee -a /etc/shells >/dev/null
LOGIN_SHELL="$(dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}')"
if [[ "${LOGIN_SHELL}" != "${SHELL_BIN}" ]]; then
  echo "Changing login shell to ${SHELL_BIN} (chsh will prompt for your password)..."
  chsh -s "${SHELL_BIN}" || echo "chsh needs an interactive password; run it yourself."
fi

echo "macOS standalone setup complete. Happy Coding 🧉"
