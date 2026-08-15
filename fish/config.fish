# Environment and $PATH live in conf.d/00-env.fish, sourced before this file.

# The directory is the only thing that says which account a shell belongs to,
# so it is what routes AWS_PROFILE and CLAUDE_CONFIG_DIR.
function __ctx --description 'work under ~/work, empty everywhere else'
    if string match -q -- "$HOME/work" "$PWD"
        or string match -q -- "$HOME/work/*" "$PWD"
        echo work
    end
end

function claude --description 'Claude Code, config picked by the working directory'
    set -l session (__ctx)

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

function ask --description 'One-off question to Claude, no session'
    if test (count $argv) -eq 0
        echo 'ask: <question>   — try the ? abbreviation' >&2
        return 2
    end

    # Bare `claude`, not `command claude`: the function above picks the config
    # dir, or a question asked under ~/work logs in as personal.
    #
    # --disallowedTools is what makes this read-only. --allowedTools only
    # auto-approves, it does not restrict, so on its own `ask 'save a file
    # called notes.txt'` writes the file. There is no "only these".
    #
    # --verbose is required, not noise: without it stream-json prints nothing.
    # jq -j concatenates the deltas, --unbuffered flushes them as they arrive —
    # drop it and the buffering it exists to remove comes straight back.
    claude -p --safe-mode --no-session-persistence --strict-mcp-config \
        --disable-slash-commands --model sonnet --effort low \
        --output-format stream-json --include-partial-messages --verbose \
        --allowedTools WebSearch WebFetch \
        --disallowedTools Bash Write Edit NotebookEdit Read Glob Grep Task \
        --system-prompt 'Answer directly and concisely: a few sentences, no preamble, no follow-up offers. Search the web when the answer depends on current or recent information, and cite the sources when you do. Reply in the language of the question.' \
        -- "$argv" \
        | jq --unbuffered -j 'select(.type == "stream_event" and .event.delta.type == "text_delta") | .event.delta.text'

    # $pipestatus, not $status: $status here is jq's, and jq happily exits 0
    # after printing nothing at all when claude dies.
    set -l rc $pipestatus[1]
    echo
    if test $rc -ne 0
        echo "ask: claude exited $rc" >&2
    end
    return $rc
end

# mise is NOT activated here: Homebrew's vendor_conf.d/mise-activate.fish
# already does it. To disable the vendor one: MISE_FISH_AUTO_ACTIVATE=0.

if status is-interactive
    set -g fish_greeting

    # Frees Ctrl-S/Ctrl-Q, which the terminal was swallowing.
    stty -ixon 2>/dev/null

    # ~/.aws/config has no [default] profile: without this every aws command
    # outside ~/work fails with NoCredentials. On PWD rather than once at
    # startup, because a directory can change under a shell and a workspace
    # could not — Starship's aws module is what makes the switch visible.
    function _aws_profile --on-variable PWD --description 'AWS profile follows the directory'
        if test "$(__ctx)" = work
            set -gx AWS_PROFILE work
        else
            set -gx AWS_PROFILE personal
        end
    end
    _aws_profile

    # `? ` expands to `ask ""` with the cursor already between the quotes. An
    # abbreviation and not a `?` function on purpose: typed bare, `? why is 5 > 3`
    # is a redirection and fish silently writes a file named 3 instead of asking
    # anything. Inside the quotes, > | & ; # and apostrophes are all just text.
    abbr -a --position command --set-cursor -- '?' 'ask "%"'

    abbr -a gc 'git commit -m'
    abbr -a gco 'git checkout'
    abbr -a ga 'git add'
    abbr -a gb 'git branch'
    abbr -a gd 'git diff'

    alias code 'code --new-window'

    # Mandatory, not a preference: on macOS eza resolves its config through the
    # native strategy and reads ~/Library/Application Support/eza, ignoring
    # XDG_CONFIG_HOME. Without this the theme is silently never loaded.
    set -gx EZA_CONFIG_DIR $HOME/.config/eza

    if command -q eza
        # --icons=auto and never a bare --icons: the value is optional, so the
        # flag eats whatever token follows it and `ls somedir` dies with
        # "invalid value for --icons". auto also drops the glyphs when the
        # output is a pipe, which is what keeps `ls | grep` matching.
        alias ls 'eza --icons=auto --group-directories-first'
        alias ll 'eza --icons=auto --group-directories-first --long --git --header'
        alias la 'eza --icons=auto --group-directories-first --long --git --header --all'
        alias lt 'eza --icons=auto --group-directories-first --tree --level=2'
    end

    set -gx BAT_THEME ansi

    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'

    # Colours by ANSI name, not hex: the sixteen slots in ghostty/config are
    # the single source.
    set -gx FZF_DEFAULT_OPTS '
      --height 40% --layout=reverse --border=rounded
      --bind="ctrl-/:toggle-preview,ctrl-y:execute-silent(echo {} | pbcopy)+abort"
      --color=bg+:bright-black,fg:white,fg+:bright-white,hl:bright-cyan,hl+:cyan,info:bright-black,prompt:blue,pointer:bright-red,marker:bright-green,border:bright-black,header:blue,spinner:cyan'

    set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :200 {}'"
    set -gx FZF_ALT_C_OPTS "--preview 'ls -la {} | head -100'"
    # Taller than the default 40%: history is the one list where the match is
    # rarely in the first rows. The preview is what makes a long or wrapped
    # command readable, and bat reads BAT_THEME=ansi, so it lands on the same
    # sixteen slots as everything above.
    set -gx FZF_CTRL_R_OPTS '
      --height=60%
      --preview="echo {} | bat --color=always --style=plain --language=fish"
      --preview-window=down:5:wrap
      --header="ctrl-y copy · ctrl-/ preview"'

    # mise stays out on purpose: its output interpolates the current $PATH, so a
    # cached copy would pin one shell's PATH onto every later shell.
    set -l init_cache $HOME/.cache/fish/init.fish
    if not test -s $init_cache
        or test (status filename) -nt $init_cache
        or test /opt/homebrew/bin -nt $init_cache
        mkdir -p (path dirname $init_cache)
        begin
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

    # A copy of fish's own down-or-search with the last branch swapped: where
    # fish starts a forward history search, this opens fzf's widget instead.
    # The three branches above it are not optional — down also drives the
    # completion pager and multi-line cursor movement.
    function fzf-history-down --description 'fzf history, or move down a line'
        if commandline --search-mode
            commandline -f history-search-forward
            return
        end

        if commandline --paging-mode
            commandline -f down-line
            return
        end

        # -lt, not fish's `switch` on equality: on an empty buffer the line
        # count is 0 while the cursor line is 1, and fzf should still open.
        if test (commandline -L) -lt (count (commandline))
            commandline -f down-line
            return
        end

        fzf-history-widget
    end

    # fish re-applies the preset bindings whenever $fish_key_bindings changes
    # and calls this function afterwards, so every custom bind has to live in
    # here — fzf's included, or Ctrl-R/T and Alt-C get dropped on a rebind.
    function fish_user_key_bindings
        functions -q fzf_key_bindings; and fzf_key_bindings

        # Ctrl-R is left to fzf_key_bindings above. It used to be rebound to
        # fish's history-pager, which forks nothing but only matches prefixes.
        for mode in insert default
            bind -M $mode ctrl-p up-or-search
            bind -M $mode ctrl-n down-or-search
            bind -M $mode ctrl-o edit_command_buffer
            # Guarded: fzf-history-widget is defined by fzf_key_bindings above,
            # so without fzf it does not exist and down would break outright.
            # Unbound, the preset down-or-search stands.
            functions -q fzf-history-widget; and bind -M $mode down fzf-history-down
        end
    end

    # The other direction needs a long escape timeout, which delays every
    # Alt-<key> too — with macos-option-as-alt the terminal sends those as
    # ESC+key.
    set -g fish_key_bindings fish_hybrid_key_bindings

    set -g fish_cursor_default block
    set -g fish_cursor_insert line blink
    set -g fish_cursor_replace_one underscore
    set -g fish_cursor_replace underscore
    set -g fish_cursor_visual block
    set -g fish_cursor_external line blink

    # Ghostty turns the bell into a Dock bounce and a title marker, so a
    # background window still reaches you without anything catching it first.
    set -g _notify_threshold 10000
    set -g _notify_ignore less man ssh claude fzf watch top tail

    function _notify_long_command --on-event fish_postexec --description 'Bell after a long command'
        test -n "$argv[1]"; or return
        set -l cmd (string split -f1 ' ' -- (string trim -- $argv[1]))
        contains -- $cmd $_notify_ignore; and return
        test $CMD_DURATION -ge $_notify_threshold; and printf '\a'
    end

    # Only STARSHIP_PNPM: starship has no pnpm module and its detect_files does
    # not walk ancestors. The docker half used to live here and was dropped —
    # starship's own docker_context reads the same config.json and hides the
    # same two contexts, default and desktop-linux.
    #
    # Builtins only: no forks, and nothing that can clobber the $status the
    # exit-code module reads — hence the last_status dance below.
    function _starship_env --on-event fish_prompt --description 'Prompt env vars starship reads'
        set -l last_status $status

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
