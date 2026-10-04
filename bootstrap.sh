#!/usr/bin/env bash
# curl -fsSL https://raw.githubusercontent.com/nhnvrr/dotfiles/main/bootstrap.sh | bash

set -euo pipefail

REPO="nhnvrr/dotfiles"
DEST="${HOME}/Develop/dotfiles"

[[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]] || {
  echo "Needs a Mac with Apple Silicon (M1 or later)."
  exit 1
}

# The installer is a GUI dialog that returns immediately; wait for it to finish.
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing the Command Line Tools — accept the dialog."
  xcode-select --install
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

# HTTPS, not SSH: a new machine has no key yet. install.sh creates it.
if [[ -d "${DEST}/.git" ]]; then
  git -C "${DEST}" pull --ff-only
else
  mkdir -p "$(dirname "${DEST}")"
  git clone "https://github.com/${REPO}.git" "${DEST}"
fi

# stdin is curl's pipe; sudo, chsh and Homebrew's installer need the terminal.
"${DEST}/install.sh" "$@" </dev/tty

git -C "${DEST}" remote set-url origin "git@github.com:${REPO}.git"
