# Environment and $PATH live in conf.d/00-env.fish. mise is activated by
# Homebrew's vendor_conf.d, not here.

status is-interactive; or exit

set -g fish_greeting
stty -ixon 2>/dev/null

# ~/.aws/config has no [default] profile on purpose, so AWS_PROFILE must be
# explicit: work under ~/work, personal everywhere else.
function _aws_profile --on-variable PWD
    if string match -q -- "$HOME/work" "$PWD"
        or string match -q -- "$HOME/work/*" "$PWD"
        set -gx AWS_PROFILE work
    else
        set -gx AWS_PROFILE personal
    end
end
_aws_profile

# Abbreviation, not a function: bare `? why is 5 > 3` is a redirection.
abbr -a --position command --set-cursor -- '?' 'ask "%"'
abbr -a gc 'git commit -m'
abbr -a gco 'git checkout'
abbr -a gd 'git diff'

alias ls 'ls -lhG'
alias la 'ls -lahG'

set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border=rounded'
set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :200 {}'"

fzf --fish | source
