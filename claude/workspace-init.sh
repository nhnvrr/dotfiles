#!/usr/bin/env bash
# Scaffold a Claude Code config dir for one workspace: <dir>/.claude-config
# seeded with claude/base/. zshrc exports CLAUDE_CONFIG_DIR to it whenever
# $PWD is inside <dir>, so each workspace keeps its own skills, plugins, MCP
# servers and settings. Copies, not links: workspaces diverge on purpose.
#
#   claude/workspace-init.sh ~/Work
#
# Idempotent: files that already exist in the target are left alone.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $(basename "$0") <workspace-dir>" >&2
  exit 2
fi

ws="${1%/}"
base="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base"
dst="${ws}/.claude-config"

if [[ ! -d "${ws}" ]]; then
  echo "no such directory: ${ws}" >&2
  exit 1
fi

mkdir -p "${dst}"
# -n: never overwrite. Skills are copied dir by dir so a workspace can drop
# one without the next run bringing it back.
while IFS= read -r -d '' src; do
  rel="${src#"${base}"/}"
  if [[ -e "${dst}/${rel}" ]]; then
    continue
  fi
  mkdir -p "$(dirname "${dst}/${rel}")"
  cp -R "${src}" "${dst}/${rel}"
  echo "  + ${rel}"
done < <(find "${base}" -mindepth 1 \( -path "${base}/skills/*" -prune -o -type f \) -print0; find "${base}/skills" -mindepth 1 -maxdepth 1 -type d -print0)

echo "ready: ${dst}"
echo "next: cd ${ws} && claude   (then /login, /status)"
