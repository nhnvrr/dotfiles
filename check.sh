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
check "fish/config.fish"      fish -n "$DIR/fish/config.fish"
check "fish/conf.d/mise-activate.fish" fish -n "$DIR/fish/conf.d/mise-activate.fish"
for f in "$DIR"/fish/functions/*.fish; do check "fish/functions/$(basename "$f")" fish -n "$f"; done
check "fish starts interactive" fish -i -c exit
for f in "$DIR"/nushell/*.nu "$DIR"/nushell/autoload/*.nu; do
  check "nushell/${f#"$DIR"/nushell/}" nu --no-config-file -c "if not (nu-check '$f') { exit 1 }"
done
check "bobthefish cloned"     test -f "$HOME/.local/share/bobthefish/functions/fish_prompt.fish"
check "starship/starship.toml" env STARSHIP_CONFIG="$DIR/starship/starship.toml" starship print-config
# The cask puts no `ghostty` on PATH; the binary inside the bundle has the CLI.
check "ghostty/config"        /Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config --config-file="$DIR/ghostty/config"
check "tmux/tmux.conf"        tmux -f "$DIR/tmux/tmux.conf" -L check start-server \; kill-server
PGCLI_PY=$(brew --prefix pgcli 2>/dev/null)/libexec/bin/python
if [[ -x "$PGCLI_PY" ]]; then
  # Builds both stylers pgcli builds at start; a bad colour value crashes there.
  check "pgcli/config"        "$PGCLI_PY" -I -c '
import os, sys, logging, pgcli
logging.disable(logging.ERROR)
from pgcli.config import load_config
from pgcli.pgstyle import style_factory, style_factory_output
c = load_config(sys.argv[1], os.path.join(os.path.dirname(pgcli.__file__), "pgclirc"))
style_factory(c["main"]["syntax_style"], c["colors"])
style_factory_output(c["main"]["syntax_style"], c["colors"])' "$DIR/pgcli/config"
else
  skip "pgcli not installed"
fi
check "Brewfile"              brew bundle check --file="$DIR/Brewfile" --no-upgrade
# jsonc: VS Code tolerates trailing commas, json.loads does not.
check "vscode/*.json"         python3 -I -c '
import json, re, sys
for f in sys.argv[1:]:
    json.loads(re.sub(r",(\s*[}\]])", r"\1", open(f).read()))' "$DIR"/vscode/settings.json "$DIR"/vscode/keybindings.json
if command -v nvim >/dev/null 2>&1; then
  check "nvim/init.lua"       nvim --headless -u "$DIR/nvim/init.lua" +qa
else
  skip "nvim not installed"
fi
check "fzf accepts FZF_DEFAULT_OPTS" zsh -c "source <(grep '^export FZF_DEFAULT_OPTS' '$DIR/zsh/zshrc'); printf 'a\n' | fzf --filter=a"

echo "Symlinks"
linked zsh/zshenv               "$HOME/.zshenv"
linked zsh/zshrc                "$HOME/.zshrc"
linked zsh/functions            "$HOME/.config/zsh/functions"
linked fish/config.fish         "$HOME/.config/fish/config.fish"
linked fish/functions           "$HOME/.config/fish/functions"
linked nushell/env.nu           "$HOME/Library/Application Support/nushell/env.nu"
linked nushell/config.nu        "$HOME/Library/Application Support/nushell/config.nu"
linked nushell/autoload         "$HOME/Library/Application Support/nushell/autoload"
linked fish/conf.d/mise-activate.fish "$HOME/.config/fish/conf.d/mise-activate.fish"
linked starship/starship.toml   "$HOME/.config/starship.toml"
linked ghostty                  "$HOME/.config/ghostty"
linked vscode/settings.json     "$HOME/Library/Application Support/Code/User/settings.json"
linked vscode/keybindings.json  "$HOME/Library/Application Support/Code/User/keybindings.json"
linked vim/vimrc                "$HOME/.vim/vimrc"
linked vim/colors               "$HOME/.vim/colors"
linked nvim                     "$HOME/.config/nvim"
linked mise/config.toml         "$HOME/.config/mise/config.toml"
linked tmux/tmux.conf           "$HOME/.config/tmux/tmux.conf"
linked pgcli/config             "$HOME/.config/pgcli/config"
linked claude/base/statusline.sh "$HOME/.claude/statusline.sh"

echo
if (( fail == 0 )); then echo "all good"; else echo "$fail failure(s)"; fi
exit "$fail"
