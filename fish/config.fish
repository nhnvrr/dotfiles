# Environment and $PATH live in conf.d/00-env.fish, sourced before this file.

# Deliberately no ~/.curlrc: that file is read by EVERY curl invocation,
# including Homebrew's installer and any third-party script.
function req --description 'curl with sane flags; pretty-prints JSON responses'
    set -l out (curl --silent --show-error --location --compressed \
        --connect-timeout 10 --max-time 60 --globoff $argv | string collect)
    # pipestatus[1] is curl's exit code, not jq's.
    set -l code $pipestatus[1]
    test $code -ne 0; and return $code

    if command -q jq; and printf '%s' $out | jq -e . >/dev/null 2>&1
        printf '%s' $out | jq .
    else
        printf '%s\n' $out
    end
end

function __tx --argument-names name --description 'Attach or create a fixed tmux session'
    set -l dir
    switch $name
        case dev
            set dir $HOME/develop
        case work
            set dir $HOME/work
        case side
            set dir $HOME/side
        case '*'
            echo "__tx: unknown session '$name'" >&2
            return 1
    end

    tmux has-session -t=$name 2>/dev/null
    or tmux new-session -d -s $name -c $dir

    # Attaching nested breaks; inside tmux you have to switch instead.
    if test -z "$TMUX"
        tmux attach-session -t $name
    else
        tmux switch-client -t $name
    end
end

function claude --description 'Claude Code, config picked by tmux session'
    # display-message answers outside tmux too, falling back to the last active
    # session, so $TMUX is what decides — not the exit status.
    set -l session
    test -n "$TMUX"; and set session (tmux display-message -p '#S' 2>/dev/null)

    # Personal leaves it unset on purpose: Claude hashes the config dir into the
    # Keychain item name only when the variable is set, so exporting it forks
    # the login off every `claude` that does not come from fish.
    # Inline prefix, not `set -lx`: that would be scoped to the if block.
    if test "$session" = work
        CLAUDE_CONFIG_DIR=$HOME/.claude-work command claude $argv
    else
        command claude $argv
    end
end

# mise is NOT activated here: Homebrew's vendor_conf.d/mise-activate.fish
# already does it. To disable the vendor one: MISE_FISH_AUTO_ACTIVATE=0.

if status is-interactive
    set -g fish_greeting

    # Frees Ctrl-S/Ctrl-Q, which the terminal was swallowing.
    stty -ixon 2>/dev/null

    # ~/.aws/config has no [default] profile: without this every aws command
    # outside the work session fails with NoCredentials.
    set -gx AWS_PROFILE personal
    if test -n "$TMUX"
        set -l session (tmux display-message -p '#S' 2>/dev/null)
        test "$session" = work; and set -gx AWS_PROFILE work
    end

    abbr -a gc 'git commit -m'
    abbr -a gco 'git checkout'
    abbr -a ga 'git add'
    abbr -a gb 'git branch'
    abbr -a gd 'git diff'

    alias code 'code --new-window'
    alias e code
    alias dev '__tx dev'
    alias work '__tx work'
    alias side '__tx side'

    # Mandatory: on macOS eza reads ~/Library/Application Support/eza and
    # ignores XDG_CONFIG_HOME.
    set -gx EZA_CONFIG_DIR $HOME/.config/eza

    if command -q eza
        alias ls 'eza --icons --group-directories-first'
        alias ll 'eza --icons --group-directories-first --long --git --header'
        alias la 'eza --icons --group-directories-first --long --git --header --all'
        alias lt 'eza --icons --group-directories-first --tree --level=2'
    end

    set -gx BAT_THEME ansi

    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'

    # Colours by ANSI name, not hex: the terminal profile is the single source.
    set -gx FZF_DEFAULT_OPTS '
      --height 40% --layout=reverse --border=rounded
      --bind="ctrl-/:toggle-preview,ctrl-y:execute-silent(echo {} | pbcopy)+abort"
      --color=bg+:bright-black,fg:white,fg+:bright-white,hl:bright-cyan,hl+:cyan,info:bright-black,prompt:blue,pointer:bright-red,marker:bright-green,border:bright-black,header:blue,spinner:cyan'

    set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :200 {}'"
    set -gx FZF_ALT_C_OPTS "--preview 'ls -la {} | head -100'"
    set -gx FZF_CTRL_R_OPTS '--preview "echo {}" --preview-window=down:3:wrap'

    # mise stays out on purpose: its output interpolates the current $PATH, so a
    # cached copy would pin one shell's PATH onto every later shell.
    set -l init_cache $HOME/.cache/fish/init.fish
    if not test -s $init_cache
        or test (status filename) -nt $init_cache
        or test /opt/homebrew/bin -nt $init_cache
        mkdir -p (path dirname $init_cache)
        begin
            zoxide init fish
            fzf --fish
            starship init fish --print-full-init
        end >$init_cache
    end
    source $init_cache

    function starship_transient_prompt_func
        starship module character
    end

    function starship_transient_rprompt_func
        starship module time
    end

    enable_transience

    # fish does not leave search mode at the bottom, it restores the line you
    # had before searching — so ↑ has to record that line for ↓ to recognise it.
    function _up_or_search_origin --description 'up-or-search, recording the pre-search line'
        commandline --search-mode; or set -g _history_origin "$(commandline)"
        up-or-search
    end

    function _down_or_fzf_history --description 'down-or-search, fzf at the bottom'
        if commandline --paging-mode
            commandline -f down-line
        else if commandline --search-mode
            if test "$(commandline)" = "$_history_origin"
                functions -q fzf-history-widget; and fzf-history-widget
            else
                commandline -f history-search-forward
            end
        else if test (commandline -L) -lt (count (commandline))
            commandline -f down-line
        else
            functions -q fzf-history-widget; and fzf-history-widget
        end
    end

    # fish re-applies the preset bindings whenever $fish_key_bindings changes
    # and calls this function afterwards, so every custom bind has to live in
    # here — fzf's included, or Ctrl-R/T and Alt-C get dropped on a rebind.
    function fish_user_key_bindings
        functions -q fzf_key_bindings; and fzf_key_bindings

        # Ctrl-R has to be rebound after fzf_key_bindings, which claims it.
        for mode in insert default
            bind -M $mode ctrl-p _up_or_search_origin
            bind -M $mode ctrl-n down-or-search
            bind -M $mode ctrl-o edit_command_buffer
            bind -M $mode up _up_or_search_origin
            bind -M $mode down _down_or_fzf_history
            bind -M $mode ctrl-r history-pager
        end
    end

    # The other direction needs a long escape timeout, which delays every
    # Alt-<key> too — the terminal sends those as ESC+key.
    set -g fish_key_bindings fish_hybrid_key_bindings

    set -g fish_cursor_default block
    set -g fish_cursor_insert line blink
    set -g fish_cursor_replace_one underscore
    set -g fish_cursor_replace underscore
    set -g fish_cursor_visual block
    set -g fish_cursor_external line blink

    # tmux catches the bell: monitor-bell flags the window in the status bar.
    set -g _notify_threshold 10000
    set -g _notify_ignore nvim less man ssh tmux claude fzf watch top tail dev work side

    function _notify_long_command --on-event fish_postexec --description 'Bell after a long command'
        test -n "$argv[1]"; or return
        set -l cmd (string split -f1 ' ' -- (string trim -- $argv[1]))
        contains -- $cmd $_notify_ignore; and return
        test $CMD_DURATION -ge $_notify_threshold; and printf '\a'
    end

    set -g _docker_default_contexts default desktop-linux

    # Builtins only: no forks, and nothing that can clobber the $status the
    # exit-code module reads — hence the last_status dance below.
    function _starship_env --on-event fish_prompt --description 'Prompt env vars starship reads'
        set -l last_status $status

        # $DOCKER_CONTEXT wins over the file, which is docker's own precedence.
        set -l ctx $DOCKER_CONTEXT
        if test -z "$ctx"; and test -r $HOME/.docker/config.json
            set ctx (string match -rg '"currentContext"\s*:\s*"([^"]+)"' <$HOME/.docker/config.json)
        end
        if test -n "$ctx"; and not contains -- $ctx $_docker_default_contexts
            set -gx STARSHIP_DOCKER_CTX $ctx
        else
            set -e STARSHIP_DOCKER_CTX
        end

        set -e STARSHIP_PNPM
        set -l dir $PWD
        while test -n "$dir"
            if test -f $dir/pnpm-lock.yaml
                set -gx STARSHIP_PNPM 1
                break
            end
            test "$dir" = "$HOME"; and break
            set dir (string replace -r '/[^/]*$' '' -- $dir)
        end

        return $last_status
    end
end
