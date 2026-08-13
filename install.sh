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
# The day/night switch. It resolves the repo from this symlink, three levels up,
# so it has to be linked and not copied.
link_file "${CONFIG_DIR}/fish/functions/theme.fish" "${HOME}/.config/fish/functions/theme.fish"
link_file "${CONFIG_DIR}/starship/starship.toml" "${HOME}/.config/starship.toml"
link_file "${CONFIG_DIR}/mise/config.toml" "${HOME}/.config/mise/config.toml"
link_file "${CONFIG_DIR}/eza/theme.yml" "${HOME}/.config/eza/theme.yml"
# The whole directory, not init.lua alone: the config is modules under
# nvim/lua/config/ now and a per-file list would need a line for each new one.
# vim.pack also writes nvim-pack-lock.json here, so plugin revisions end up
# versioned — the same deliberate side effect as ~/.gitconfig being a symlink.
link_file "${CONFIG_DIR}/nvim" "${HOME}/.config/nvim"
link_file "${CONFIG_DIR}/hammerspoon/init.lua" "${HOME}/.hammerspoon/init.lua"
link_file "${CONFIG_DIR}/alacritty/alacritty.toml" "${HOME}/.config/alacritty/alacritty.toml"
# The six theme files. Linked as a directory: `theme` copies one of them over
# ~/.config/alacritty/theme.toml, which is mutable state and deliberately NOT a
# symlink — a link into the repo would have every switch write in the working tree.
link_file "${CONFIG_DIR}/alacritty/themes" "${HOME}/.config/alacritty/themes"
# herdr is not linked, unlike every other config here: `theme` rewrites its
# dark_name/light_name per family, so the deployed file is a derived copy. Only
# config.toml would have been linked anyway — herdr keeps its sockets, logs,
# session.json and installed plugins in the same directory, and none of that is
# config.
# The theme goes in by name, not by path — btop.conf asks for "current" and btop
# looks it up under ~/.config/btop/themes. That name is not linked here and is not
# a file in this repo either: `theme` generates it from the sixteen slots of
# whichever palette is live, so there is one template instead of six near-copies.
# The template itself is read straight out of the repo and deliberately not linked
# in here — btop lists every *.theme in this directory, and one full of unresolved
# placeholders would show up as a selectable theme.
# Linking the config is only safe because it sets save_config_on_exit = false;
# otherwise btop would write back through the symlink every time it is closed.
link_file "${CONFIG_DIR}/btop/btop.conf" "${HOME}/.config/btop/btop.conf"
# psql won't create this directory and history fails silently without it.
mkdir -p "${HOME}/.local/state/psql"
link_file "${CONFIG_DIR}/psql/psqlrc" "${HOME}/.psqlrc"
# Same trap. Not linked, unlike every other config here: syntax_style is the one
# setting in the stack that is neither an ANSI slot nor a path — a pygments style
# name resolved inside Python — so `theme` deploys a copy with that single line
# rewritten. The cost is that editing pgcli/config needs a `theme` run to land.
mkdir -p "${HOME}/.local/state/pgcli"
# Same trap, for both redis clients.
mkdir -p "${HOME}/.local/state/iredis" "${HOME}/.local/state/redis"
link_file "${CONFIG_DIR}/redis/iredisrc" "${HOME}/.iredisrc"
if [[ -f "${CONFIG_DIR}/gh/config.yml" ]]; then
  link_file "${CONFIG_DIR}/gh/config.yml" "${HOME}/.config/gh/config.yml"
fi

# No terminfo step here on purpose: TERM=alacritty is missing from the system
# database too, but the cask declares ~/.terminfo/61/alacritty as one of its
# own artifacts, so `brew bundle` symlinks it out of the bundle already.

# Orphans from previous setups. Removed only if they point into this repo, so a
# hand-written file at any of these paths stays untouched.
for stale in "${HOME}/.zshrc" \
             "${HOME}/.zprofile" \
             "${HOME}/.tmux.conf" \
             "${HOME}/.config/ghostty/config" \
             "${HOME}/.config/atuin/config.toml" \
             "${HOME}/.config/btop/themes/nord-slots.theme" \
             "${HOME}/.config/btop/themes/nord-slots-light.theme" \
             "${HOME}/.config/herdr/config.toml"; do
  if [[ -L "${stale}" && "$(readlink "${stale}")" == "${CONFIG_DIR}"/* ]]; then
    rm -f "${stale}"
    echo "  removed stale symlink ${stale}"
  fi
done
rm -f "${HOME}/.cache/zsh/init.zsh"

for broken in "${HOME}/.zshenv" "${HOME}/.bashrc" "${HOME}/.bash_profile" "${HOME}/.profile"; do
  if [[ -L "${broken}" && ! -e "${broken}" ]]; then
    rm -f "${broken}"
    echo "  removed broken symlink ${broken}"
  fi
done

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

# Seeds alacritty's theme.toml, btop's generated current.theme, pgcli's config and
# herdr's, all through the same code path the switch uses, so there is only ever
# one. Keeps whatever is already live; on a machine with nothing, gruvbox dark —
# the half with the strongest body text of the six, 10.75:1.
if [[ -n "${FISH_BIN}" ]]; then
  echo "Deploying the terminal theme..."
  THEME_LIVE="$("${FISH_BIN}" -c theme 2>/dev/null || true)"
  [[ -n "${THEME_LIVE}" ]] || THEME_LIVE="gruvbox dark"
  "${FISH_BIN}" -c "theme ${THEME_LIVE}"
fi

echo "macOS standalone setup complete. Happy Coding 🧉"
