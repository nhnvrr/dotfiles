# Fish, the default shell. zsh/ stays installed and linked as the fallback.
# mise runs in shims mode: conf.d/mise-activate.fish shadows Homebrew's hook,
# which ran `mise hook-env` twice per Enter (~60 ms). Shims resolve per directory.

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
# Argument order is the resulting order, same as zshenv.
fish_add_path -g -m -P $HOME/.local/share/mise/shims $GOPATH/bin /opt/homebrew/bin /opt/homebrew/sbin \
    /opt/homebrew/opt/libpq/bin $HOME/.bun/bin $HOME/.local/bin $PNPM_HOME/bin $HOME/.docker/bin /usr/local/bin

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
    # bobthefish calls `nvm current` on every prompt; answer it without bash.
    if test "$argv" = current
        string match -qr '/(?<v>v[^/]+)/bin$' -- $_nvm_current; and echo $v; or echo none
        return
    end
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
function fish_greeting
end
set -g fish_escape_delay_ms 10
set -g fish_key_bindings fish_vi_key_bindings
set -g fish_cursor_default block
set -g fish_cursor_insert line blink
set -g fish_cursor_replace_one underscore
set -g fish_cursor_visual block

abbr -a gc 'git commit -m'
abbr -a gco git checkout
abbr -a gd git diff
abbr -a lg lazygit
abbr -a dw 'cd ~/Downloads'
abbr -a docu 'cd ~/Documents'
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
# kubectl's completion costs ~90 ms to source, so it is generated into a
# completions dir and fish autoloads it on the first `kubectl <tab>`.
if type -q kubectl
    set -l dir $HOME/.cache/fish/completions
    set -l file $dir/kubectl.fish
    if not test -s $file; or test (command -s kubectl) -nt $file
        mkdir -p $dir
        kubectl completion fish >$file 2>/dev/null
    end
    contains $dir $fish_complete_path; or set -p fish_complete_path $dir
end

# --- prompt ------------------------------------------------------------------
# bobthefish, cloned by install.sh; Starship stays zsh-only. Its functions go
# right after ~/.config/fish/functions so nothing of ours is shadowed.
set -l bob $HOME/.local/share/bobthefish/functions
if test -d $bob; and not contains $bob $fish_function_path
    set -g fish_function_path $fish_function_path[1] $bob $fish_function_path[2..]
end

# The fish_prompt.fish internals below must be redefined after it autoloads,
# or the autoload would put the originals back.
if functions -q fish_prompt

    # Git, fast: bobthefish spawns ~7 git processes per prompt (~90 ms here).
    # The repo root is found without a process and the state comes from one
    # `git status --porcelain=v2`. Tags are not shown.
    function __bobthefish_git_project_dir -S -a real_pwd
        set -l d $real_pwd
        while test -n "$d"
            test -e $d/.git; and echo $d; and return
            test "$d" = /; and return
            set d (path dirname $d)
        end
    end
    function __bobthefish_prompt_git -S -a git_root_dir -a real_pwd
        set -l branch
        set -l oid
        set -l ab
        set -l dirty ''
        set -l staged ''
        set -l stashed ''
        for line in (command git --no-optional-locks status --porcelain=v2 --branch --show-stash --untracked-files=no 2>/dev/null)
            switch $line
                case '# branch.head *'
                    set branch (string sub -s 15 -- $line)
                case '# branch.oid *'
                    set oid (string sub -s 14 -l 7 -- $line)
                case '# branch.ab *'
                    set ab (string split ' ' -- $line)[3..4]
                case '# stash *'
                    set stashed $git_stashed_glyph
                case '1 *' '2 *'
                    test (string sub -s 3 -l 1 -- $line) != .; and set staged $git_staged_glyph
                    test (string sub -s 4 -l 1 -- $line) != .; and set dirty $git_dirty_glyph
                case 'u *'
                    set dirty $git_dirty_glyph
            end
        end
        set -l ahead ''
        if test (count $ab) -eq 2
            set -l a (string sub -s 2 -- $ab[1])
            set -l b (string sub -s 2 -- $ab[2])
            if test $a -gt 0 -a $b -gt 0
                set ahead $git_plus_minus_glyph
            else if test $a -gt 0
                set ahead $git_plus_glyph
            else if test $b -gt 0
                set ahead $git_minus_glyph
            end
        end
        set -l flags "$dirty$staged$stashed$ahead"
        test -n "$flags"; and set flags " $flags"
        set -l flag_colors $color_repo
        if test -n "$dirty"
            set flag_colors $color_repo_dirty
        else if test -n "$staged"
            set flag_colors $color_repo_staged
        end

        __bobthefish_path_segment $git_root_dir project
        __bobthefish_start_segment $flag_colors
        switch "$branch"
            case '(detached)'
                echo -ns $detached_glyph ' ' $oid
            case main master
                echo -ns $branch_glyph
            case '*'
                echo -ns $branch_glyph ' ' $branch
        end
        echo -ns $flags ' '
        set_color normal

        set -l project_pwd (__bobthefish_project_pwd $git_root_dir $real_pwd)
        if test -n "$project_pwd"
            if test -w "$real_pwd"
                __bobthefish_start_segment $color_path
            else
                __bobthefish_start_segment $color_path_nowrite
            end
            echo -ns $project_pwd ' '
        end
    end

    # Transient prompt: once a command runs, its line collapses to ❯ in the
    # scrollback. The wrapper hands bobthefish the real $status back.
    functions -c fish_prompt __bobthefish_fish_prompt
    function _return -a code
        return $code
    end
    function fish_prompt
        set -l last $status
        if contains -- --final-rendering $argv
            test $last -eq 0; and set_color green; or set_color red
            echo -n '❯ '
            set_color normal
            return
        end
        _return $last
        __bobthefish_fish_prompt
    end
    functions -q fish_right_prompt
    # bobthefish's right prompt, with the date in magenta (slot 5) instead of
    # fish_color_autosuggestion.
    function fish_right_prompt
        contains -- --final-rendering $argv; and return
        set -l __bobthefish_left_arrow_glyph \uE0B3
        set_color $fish_color_autosuggestion
        __bobthefish_cmd_duration
        set_color magenta
        __bobthefish_timestamp
        set_color normal
    end
end
set -g fish_transient_prompt 1

set -g theme_show_exit_status yes
set -g theme_display_k8s_context yes
set -g theme_display_git_untracked no
# Intermediate dirs cut to one letter, the last one kept whole, inside a repo too.
set -g fish_prompt_pwd_dir_length 1
set -g theme_project_dir_length 1
set -g theme_nerd_fonts yes
set -g theme_display_node yes
# Off: fish does not pass --final-rendering to the mode prompt, so the mode
# would stay in the transient line. The cursor shape already shows the mode.
set -g theme_display_vi no
set -g theme_date_format '+%a %d %b %H:%M:%S'
set -g theme_title_use_abbreviated_path yes
# terminal-* schemes draw with ANSI slots, so the prompt follows Ghostty's mate.
if string match -q '*mate-light*' -- (cat $HOME/.config/ghostty/mode.local 2>/dev/null)
    set -g theme_color_scheme terminal-light
else
    set -g theme_color_scheme terminal-dark
end
