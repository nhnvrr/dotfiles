# The prompt. Sourced from .zshrc; lives apart the way fish kept fish_prompt
# and 10-git-prompt in separate files.
#
# ANSI names, not hex: the active theme's sixteen slots are the single source.
# Plain ASCII state markers, so ssh and Terminal.app draw the same prompt with
# no patched font, and no double-width glyph to knock the cursor column out of
# step with what the terminal drew.

# ${vcs_info_msg_0_} prints literally without this.
setopt PROMPT_SUBST

autoload -Uz vcs_info add-zsh-hook
add-zsh-hook precmd vcs_info

# git only: the other eleven backends are one stat() each, every prompt.
zstyle ':vcs_info:*' enable git

# check-for-changes is deliberately OFF. It runs two git diffs for %u and %c,
# and the untracked, stash and ahead/behind markers needed three forks more:
# ~80ms per prompt, which you feel. +vi-git-status below gets all five out of a
# single `git status`, for ~30ms.
zstyle ':vcs_info:git:*' check-for-changes false

# %m is whatever the hook leaves in hook_com[misc]. During a rebase or a merge
# the git backend fills that same slot with patch info -- a 40-char SHA, the
# subject line and "(n applied)" -- which bursts the prompt. Emptying both
# patch formats hands %m back to the hook.
zstyle ':vcs_info:git*:*' patch-format ''
zstyle ':vcs_info:git*:*' nopatch-format ''

zstyle ':vcs_info:git:*' formats       ' %F{green}%b%f%m'
zstyle ':vcs_info:git:*' actionformats ' %F{green}%b%f|%F{red}%a%f%m'

zstyle ':vcs_info:git+set-message:*' hooks git-status git-shorten-branch

# If a monorepo ever makes even one `git status` too slow to sit in a prompt:
#   zstyle ':vcs_info:*' disable-patterns "${HOME}/path/to/monorepo(|/*)"

# One fork, five markers. porcelain=v2 is the stable machine format:
#   # branch.ab +2 -1        ahead/behind, only when there is an upstream
#   # stash 3                from --show-stash
#   1 .M ... / 2 / u XY      X is the staged column, Y the unstaged one
#   ? path                   untracked
function +vi-git-status {
  local line staged unstaged untracked stash ahead behind
  local -a lines words

  lines=("${(@f)$(git status --porcelain=v2 --branch --show-stash 2>/dev/null)}")

  for line in $lines; do
    case $line in
      '# branch.ab '*)
        words=(${=line})
        ahead=${words[3]#+}
        behind=${words[4]#-}
        ;;
      '# stash '*) stash=1 ;;
      '? '*)       untracked=1 ;;
      [12u]' '*)
        [[ ${line[3]} != '.' ]] && staged=1
        [[ ${line[4]} != '.' ]] && unstaged=1
        ;;
    esac
    # The file list runs to thousands of lines in a big repo and the markers are
    # booleans; nothing after this point can change the answer.
    [[ -n $staged && -n $unstaged && -n $untracked ]] && break
  done

  [[ -n $unstaged  ]] && hook_com[misc]+='%F{yellow}*%f'
  [[ -n $staged    ]] && hook_com[misc]+='%F{green}+%f'
  [[ -n $untracked ]] && hook_com[misc]+='%F{cyan}?%f'
  [[ -n $stash     ]] && hook_com[misc]+='%F{yellow}$%f'
  (( ahead  )) && hook_com[misc]+="%F{white}⇡${ahead}%f"
  (( behind )) && hook_com[misc]+="%F{white}⇣${behind}%f"

  # Mandatory. VCS_INFO_hook breaks out of its loop the moment a hook returns
  # non-zero, silently skipping every hook after it -- and the last line above
  # returns 1 whenever the branch is not behind.
  return 0
}

# Worktree branches run to 50+ chars (bug/sc-10957-propagate-on-conflict-...)
# and push the chevron off the edge. 15 keeps bug/sc-NNNNN, the part that
# identifies the work.
#
# Writing hook_com is enough. Never set ret here: in a set-message hook a
# non-zero ret makes vcs_info drop the whole message, and the prompt loses its
# git block entirely.
function +vi-git-shorten-branch {
  if (( ${#hook_com[branch]} > 15 )); then
    hook_com[branch]="${hook_com[branch][1,15]}…"
  fi
  return 0
}

# %~ is the whole path, abbreviating nothing. Not %2~: that one drops the
# leading components instead of shortening them, so ~/work/x and ~/Develop/x
# render identically.
#
# %m is the hostname up to the first dot -- `mbp`, not `mbp.local`. If it ever
# reads as Nicolass-MacBook-Pro, fix it with `scutil --set HostName`, not here.
#
# %(?.a.b) is the exit status of the last command; no precmd needed to capture it.
PROMPT='%F{cyan}%n%f%F{white}@%m%f %F{white}%~%f${vcs_info_msg_0_} %(?.%F{white}.%F{red})❯%f '
RPROMPT='%F{red}%D{%H:%M:%S %z}%f'
