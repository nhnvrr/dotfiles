# The prompt. Sourced from .zshrc.
#
# ANSI colour names, not hex: whatever palette the terminal is serving.
# Plain ASCII state markers, so ssh and Terminal.app draw the same prompt with
# no patched font, and no double-width glyph to knock the cursor column out of
# step with what the terminal drew.

# ${vcs_info_msg_0_} prints literally without this.
setopt PROMPT_SUBST

autoload -Uz vcs_info add-zsh-hook

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

# Leading space, not trailing: the block sits right after the path in PROMPT.
# U+E0A0 is the powerline branch glyph; Ioskeley ships it.
zstyle ':vcs_info:git:*' formats       $' %F{green}\ue0a0 %b%f%m'
zstyle ':vcs_info:git:*' actionformats $' %F{green}\ue0a0 %b%f|%F{red}%a%f%m'

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
  # cyan, not green: a green + right after the green branch is a + you cannot see.
  [[ -n $staged    ]] && hook_com[misc]+='%F{cyan}+%f'
  [[ -n $untracked ]] && hook_com[misc]+='%F{red}?%f'
  [[ -n $stash     ]] && hook_com[misc]+='%F{magenta}$%f'
  (( ahead  )) && hook_com[misc]+="%F{blue}⇡${ahead}%f"
  (( behind )) && hook_com[misc]+="%F{blue}⇣${behind}%f"

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

# Integer SECONDS reports everything under a second as 0s.
typeset -F SECONDS

typeset -g _mate_cmd_start=
typeset -g _mate_elapsed=
typeset -g _mate_chevrons='❯'

# %{...%} tells zsh these bytes take no columns. Without it the italic escapes
# are counted as printable and RPROMPT is placed that many columns too far left.
typeset -g _mate_italic_on=$'%{\e[3m%}'
typeset -g _mate_italic_off=$'%{\e[23m%}'

# SGR 22 clears bold as well as faint. Nothing here is bold -- PROMPT dropped
# its %B, and the terminal draws SGR 1 at Regular -- so there is nothing to lose.
typeset -g _mate_faint_on=$'%{\e[2m%}'
typeset -g _mate_faint_off=$'%{\e[22m%}'

function _mate_preexec_timer { _mate_cmd_start=$SECONDS }
add-zsh-hook preexec _mate_preexec_timer

# Writes to $REPLY instead of printing: $(...) around this would be a fork per
# prompt, which is the thing the rest of this file goes out of its way to avoid.
# printf -v for the same reason.
function _mate_format_elapsed {
  local -F delta=$1
  local -i d h m
  typeset -g REPLY=''

  d=$(( delta / 86400 ))
  h=$(( (delta - d * 86400) / 3600 ))
  m=$(( (delta - d * 86400 - h * 3600) / 60 ))
  local -F s=$(( delta - d * 86400 - h * 3600 - m * 60 ))

  (( d )) && REPLY+="${d}d"
  (( h )) && REPLY+="${h}h"
  (( m )) && REPLY+="${m}m"

  if (( d )); then
    :                          # past a day the seconds are noise
  elif [[ -n $REPLY ]]; then
    # Not int(): that one lives in zsh/mathfunc. Assigning to an integer
    # truncates just the same, with no module to load.
    local -i whole=$s
    REPLY+="${whole}s"
  else
    local fmt
    printf -v fmt '%.2f' $s
    REPLY+="${fmt}s"
  fi
}

# One precmd for all three. The relative order of separate add-zsh-hook calls
# is just the order the lines happen to sit in, and RPROMPT needs both the
# elapsed time and vcs_info already computed.
function _mate_precmd {
  if [[ -n $_mate_cmd_start ]]; then
    _mate_format_elapsed $(( SECONDS - _mate_cmd_start ))
    # No %F: every ANSI colour already means something else in the prompt.
    _mate_elapsed="${_mate_faint_on}${_mate_italic_on}${REPLY}${_mate_italic_off}${_mate_faint_off} "
    _mate_cmd_start=
  else
    _mate_elapsed=''
  fi

  # One ❯ per nesting level. Inside tmux $SHLVL already counts the shell tmux
  # itself spawned, so it arrives one too high.
  local -i lvl=$SHLVL
  [[ -n $TMUX ]] && (( lvl-- ))
  (( lvl < 1 )) && lvl=1
  _mate_chevrons=''
  repeat $lvl _mate_chevrons+='❯'

  vcs_info
}
add-zsh-hook precmd _mate_precmd

# Buys back a column. Only inside tmux: outside it, zsh eats the space after
# PS1 instead and the prompt comes out corrupted.
[[ -n $TMUX ]] && export ZLE_RPROMPT_INDENT=0

# %~ and not %2~: that one drops the leading components instead of shortening
# them, so ~/work/x and ~/Develop/x render identically.
#
#   %~         $PWD with $HOME as ~
#   %(1j.*.)   a * while there are background jobs, before the branch so it
#              is never read as the branch's unstaged *
#   %(?..!)    a ! when the last command exited non-zero
#   %(!.a.b)   root vs not
#
# No %B anywhere: colour already separates every one of these, and weight is
# handled once in alacritty.toml rather than per-escape here.
PROMPT='%F{cyan}%~%f%F{yellow}%(1j.*.)%(?..!)%f${vcs_info_msg_0_} %(!.%F{yellow}.%F{red})${_mate_chevrons}%f '

RPROMPT='${_mate_elapsed% }'
