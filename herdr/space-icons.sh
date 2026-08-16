#!/usr/bin/env bash
# Assign the $icon token to every open herdr space.
#
# Workspace metadata is ephemeral: it lives in the running server, not in
# session.json, so it must be re-applied after every `herdr server stop`.
set -euo pipefail

SOURCE="space-icons"

# No server: nothing to label. herdr exports HERDR_SOCKET_PATH inside panes.
[ -S "${HERDR_SOCKET_PATH:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr/herdr.sock}" ] || exit 0

# Nerd Font glyphs (JetBrains Mono NF), written as UTF-8 octal escapes so the
# codepoint stays readable and no editor can mangle a private-use character.
# Emoji are double-width and shift every sidebar column below them.
ICON_PROJECT=$(printf '\357\201\273')   # U+F07B folder    — project spaces
ICON_WORKTREE=$(printf '\357\204\246')  # U+F126 code-fork — linked worktrees
ICON_DOTFILES=$(printf '\357\200\223')  # U+F013 cog
ICON_NOTES=$(printf '\357\200\255')     # U+F02D book

# name -> glyph, for the few spaces that are not projects.
# Matched against the space label, then the repo name.
icon_for_name() {
  case "$1" in
    dotfiles) printf '%s' "$ICON_DOTFILES" ;;
    notes)    printf '%s' "$ICON_NOTES" ;;
    *)        return 1 ;;
  esac
}

# Spaces already carrying an icon are skipped, so this is cheap enough to call
# from every shell startup: it only does work after a server restart (which
# wipes all metadata) or when a new space appears.
herdr workspace list |
  python3 -c '
import json, sys
for w in json.load(sys.stdin)["result"]["workspaces"]:
    if (w.get("tokens") or {}).get("icon"):
        continue
    wt = w.get("worktree") or {}
    print("\t".join([
        w["workspace_id"],
        w.get("label", ""),
        wt.get("repo_name", ""),
        "1" if wt.get("is_linked_worktree") else "",
    ]))
' |
  while IFS=$'\t' read -r id label repo linked; do
    # Linked worktrees win over the name table: they share the repo name but
    # are not the project folder.
    if [ -n "$linked" ]; then
      icon=$ICON_WORKTREE
    elif icon=$(icon_for_name "$label"); then
      :
    elif [ -n "$repo" ] && icon=$(icon_for_name "$repo"); then
      :
    else
      icon=$ICON_PROJECT
    fi
    herdr workspace report-metadata "$id" --source "$SOURCE" --token "icon=$icon"
  done
