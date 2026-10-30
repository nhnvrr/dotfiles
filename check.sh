#!/usr/bin/env bash
# Smoke test: parses every config in the repo and checks the symlinks install.sh
# makes. Read-only. Exit status is the number of failures.
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail=0

ok()   { printf '  ok    %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fail=$((fail + 1)); }
skip() { printf '  skip  %s\n' "$1"; }

check() { # check <label> <command...>: passes when the command exits 0
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$label"; else bad "$label"; fi
}

linked() { # linked <repo path> <destination>: destination must point into the repo
  local dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$DIR/$1" ]]; then ok "$dst"
  elif [[ -e "$dst" ]]; then bad "$dst is not a link into the repo"
  else bad "$dst missing"; fi
}

echo "Syntax"
check "install.sh"            bash -n "$DIR/install.sh"
check "bootstrap.sh"          bash -n "$DIR/bootstrap.sh"
check "zsh/zshrc"             zsh -n "$DIR/zsh/zshrc"
check "zsh/zshenv"            zsh -n "$DIR/zsh/zshenv"
for f in "$DIR"/zsh/functions/*; do check "zsh/functions/$(basename "$f")" zsh -n "$f"; done
check "starship/starship.toml" env STARSHIP_CONFIG="$DIR/starship/starship.toml" starship print-config
# The cask puts no `ghostty` on PATH; the binary inside the bundle has the CLI.
check "ghostty/config"        /Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config --config-file="$DIR/ghostty/config"
check "tmux/tmux.conf"        tmux -f "$DIR/tmux/tmux.conf" -L check start-server \; kill-server
check "Brewfile"              brew bundle check --file="$DIR/Brewfile" --no-upgrade
# jsonc: VS Code tolerates trailing commas, json.loads does not.
check "vscode/*.json"         python3 -I -c '
import json, re, sys
for f in sys.argv[1:]:
    json.loads(re.sub(r",(\s*[}\]])", r"\1", open(f).read()))' "$DIR"/vscode/settings.json "$DIR"/vscode/keybindings.json "$DIR"/vscode/extensions/mate/themes/*.json
check "fzf accepts FZF_DEFAULT_OPTS" zsh -c "source <(grep '^export FZF_DEFAULT_OPTS' '$DIR/zsh/zshrc'); printf 'a\n' | fzf --filter=a"

echo "Hammerspoon"
if command -v hs >/dev/null 2>&1 && hs -c 'return 1' >/dev/null 2>&1; then
  keys="$(hs -c "local k=package.loaded['mate.keys']; local t={} for _,h in ipairs(k.hotkeys) do t[#t+1]=h.msg end return table.concat(t,' ')" 2>/dev/null)"
  if [[ "$keys" == "⌘⌥0 ⌘⌥- ⌘⌥=" ]]; then ok "hotkeys: $keys"; else bad "hotkeys: '$keys' (reload Hammerspoon?)"; fi
else
  skip "hs not running"
fi

echo "Symlinks"
linked zsh/zshenv               "$HOME/.zshenv"
linked zsh/zshrc                "$HOME/.zshrc"
linked zsh/functions            "$HOME/.config/zsh/functions"
linked starship/starship.toml   "$HOME/.config/starship.toml"
linked ghostty                  "$HOME/.config/ghostty"
linked vscode/settings.json     "$HOME/Library/Application Support/Code/User/settings.json"
linked vscode/keybindings.json  "$HOME/Library/Application Support/Code/User/keybindings.json"
linked vscode/extensions/mate   "$HOME/.vscode/extensions/nhnvrr.mate-theme-0.0.1"
linked vim/vimrc                "$HOME/.vim/vimrc"
linked vim/colors               "$HOME/.vim/colors"
linked hammerspoon/init.lua     "$HOME/.hammerspoon/init.lua"
linked hammerspoon/mate         "$HOME/.hammerspoon/mate"
linked mise/config.toml         "$HOME/.config/mise/config.toml"
linked tmux/tmux.conf           "$HOME/.config/tmux/tmux.conf"
linked claude/base/statusline.sh "$HOME/.claude/statusline.sh"

echo
if (( fail == 0 )); then echo "all good"; else echo "$fail failure(s)"; fi
exit "$fail"
