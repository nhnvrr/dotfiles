# Environment and $PATH live in conf.d/00-env.fish. mise is activated by
# Homebrew's vendor_conf.d, not here.

status is-interactive; or exit

set -g fish_greeting
stty -ixon 2>/dev/null

set -g fish_key_bindings fish_hybrid_key_bindings
set -g fish_cursor_default block
set -g fish_cursor_insert line blink

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
abbr -a ga 'git add'
abbr -a gb 'git branch'
abbr -a gd 'git diff'

alias code 'code --new-window'

# BSD ls: -G colours by LSCOLORS, -h human sizes.
alias ls 'ls -lhG'
alias ll 'ls -lhG'
alias la 'ls -lahG'

set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
# ANSI names, not hex: alacritty/mate.toml's sixteen slots are the single source.
set -gx FZF_DEFAULT_OPTS '
  --height 40% --layout=reverse --border=rounded
  --bind="ctrl-/:toggle-preview,ctrl-y:execute-silent(echo {} | pbcopy)+abort"
  --color=bg+:bright-black,fg:white,fg+:bright-white,hl:bright-cyan,hl+:cyan,info:bright-black,prompt:blue,pointer:bright-red,marker:bright-green,border:bright-black,header:blue,spinner:cyan'
set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :200 {}'"
set -gx FZF_ALT_C_OPTS "--preview 'ls -la {} | head -100'"
set -gx FZF_CTRL_R_OPTS '
  --height=60%
  --preview="echo {} | bat --color=always --style=plain --language=fish"
  --preview-window=down:5:wrap
  --header="ctrl-y copy · ctrl-/ preview"'

fzf --fish | source
