# Fish, the default shell. zsh/ stays installed and linked as the fallback.
# mise activates itself from Homebrew's vendor_conf.d before this file runs.

# --- environment -------------------------------------------------------------
set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
set -gx HOMEBREW_REPOSITORY /opt/homebrew

set -gx LANG en_US.UTF-8
set -gx EDITOR vim
set -gx VISUAL vim

set -gx GOPATH $HOME/Develop/go
set -gx GOPRIVATE github.com/nhnvrr
set -gx PNPM_HOME $HOME/Library/pnpm

set -gx AWS_PAGER ""
set -gx AWS_RETRY_MODE standard
set -gx AWS_MAX_ATTEMPTS 3

set -gx REDISCLI_HISTFILE $HOME/.local/state/redis/history
set -gx BAT_THEME ansi
set -gx NVM_DIR $HOME/.nvm

# fish_add_path skips missing dirs; -m moves entries path_helper already placed.
fish_add_path -g -m -P /usr/local/bin $HOME/.docker/bin $PNPM_HOME/bin $HOME/.local/bin \
    $HOME/.bun/bin /opt/homebrew/opt/libpq/bin /opt/homebrew/sbin /opt/homebrew/bin $GOPATH/bin

status is-interactive; or exit

# Static init scripts are cached and regenerated only when the binary is newer.
function _cached_source -a name
    set -l cache $HOME/.cache/fish/init-$name.fish
    set -l bin (command -s $name)
    if not test -s $cache; or test $bin -nt $cache
        mkdir -p (path dirname $cache)
        $argv[2..] >$cache
    end
    source $cache
end

# --- node (nvm without nvm.sh) ------------------------------------------------
# nvm is bash-only. Node is picked straight from ~/.nvm/versions: .nvmrc on cd,
# the default alias elsewhere. `nvm install` etc. still go through bash.
function _nvm_bin -a want
    set want (string replace -r '^v' '' -- $want)
    set -l dirs $NVM_DIR/versions/node/v$want*/bin
    test (count $dirs) -gt 0; or return 1
    printf '%s\n' $dirs | sort -V | tail -1
end

function _nvm_auto --on-variable PWD
    set -l want
    if test -f .nvmrc
        set want (string trim < .nvmrc)
    else if test -r $NVM_DIR/alias/default
        set want (string trim < $NVM_DIR/alias/default)
    else
        return
    end
    set -l bin (_nvm_bin $want)
    if test -z "$bin"
        test -f .nvmrc; and echo "node $want not installed: nvm install $want" >&2
        return
    end
    test "$_nvm_current" = $bin; and return
    set -l keep
    for p in $PATH
        string match -q "$NVM_DIR/versions/node/*" -- $p; or set -a keep $p
    end
    set -gx PATH $bin $keep
    set -g _nvm_current $bin
end
_nvm_auto

function nvm --description 'nvm through bash; node switches on cd, not with nvm use'
    bash -c 'source /opt/homebrew/opt/nvm/nvm.sh --no-use && nvm "$@"' nvm $argv
    set -e _nvm_current
    _nvm_auto
end

# --- per-directory profile and claude config ----------------------------------
function _workspace_env --on-variable PWD
    # ~/.aws/config has no [default] profile on purpose.
    switch $PWD
        case $HOME/Work $HOME/Work/'*'
            set -gx AWS_PROFILE work
        case '*'
            set -gx AWS_PROFILE personal
    end
    for ws in Work Side Orange
        switch $PWD
            case $HOME/$ws $HOME/$ws/'*'
                if test -d $HOME/$ws/.claude-config
                    set -gx CLAUDE_CONFIG_DIR $HOME/$ws/.claude-config
                    return
                end
        end
    end
    set -e CLAUDE_CONFIG_DIR
end
_workspace_env

# --- shell behaviour ---------------------------------------------------------
set -g fish_greeting
set -g fish_escape_delay_ms 10
set -g fish_key_bindings fish_vi_key_bindings
set -g fish_cursor_default block
set -g fish_cursor_insert line blink
set -g fish_cursor_replace_one underscore
set -g fish_cursor_visual block
# Starship draws the mode in its prompt character.
function fish_mode_prompt
end

abbr -a gc 'git commit -m'
abbr -a gco git checkout
abbr -a gd git diff
alias ls 'ls -lhG'
alias la 'ls -lahG'
abbr -a '?' ask

# --- fzf ---------------------------------------------------------------------
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border=rounded --color=16,fg:-1,bg:-1,fg+:-1,bg+:8,hl:3,hl+:3:bold,prompt:1,pointer:1,marker:1,spinner:3,info:8,header:4,border:8,separator:8,scrollbar:8,label:8'
set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :200 {}'"
set -gx FZF_ALT_C_OPTS "--preview 'ls -1 {}'"
set -gx FZF_CTRL_R_OPTS --exact

# Runs after fish_vi_key_bindings resets the keymap, so these binds survive it.
function fish_user_key_bindings
    _cached_source fzf fzf --fish
    for mode in default insert
        bind -M $mode tab _fzf_complete
    end
    bind -M insert ctrl-a beginning-of-line
    bind -M insert ctrl-e end-of-line
    bind -M insert ctrl-space accept-autosuggestion
    bind -M insert ctrl-f forward-word
end

# --- completions -------------------------------------------------------------
type -q aws_completer; and complete -c aws -f -a '(begin; set -lx COMP_SHELL fish; set -lx COMP_LINE (commandline); aws_completer | string replace -r \'\s+$\' \'\'; end)'
type -q kubectl; and _cached_source kubectl kubectl completion fish

# --- prompt ------------------------------------------------------------------
_cached_source starship starship init fish --print-full-init
