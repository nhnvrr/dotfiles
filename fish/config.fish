# LANG only: LC_ALL overrides every LC_* category and blocks per-category tweaks.
set -gx LANG en_US.UTF-8
set -gx EDITOR nvim
set -gx VISUAL nvim

set -g fish_greeting

# fish_add_path -g, not -U: writes the session $PATH instead of the universal
# $fish_user_paths, which is state outside the repo and drifts.
set -gx GOPATH $HOME/Develop/go
set -gx GOPRIVATE github.com/nhnvrr
fish_add_path -g $GOPATH/bin /opt/homebrew/bin /opt/homebrew/sbin \
    /opt/homebrew/opt/libpq/bin /usr/local/bin $HOME/.local/bin

alias e 'code --new-window'
alias code 'code --new-window'

# abbr, not alias: expands on screen when you hit space, so you see the real
# command before running it and history stores the expanded form.
abbr -a gc 'git commit -m'
abbr -a gco 'git checkout'
abbr -a ga 'git add'
abbr -a gb 'git branch'
abbr -a gd 'git diff'

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

alias dev '__tx dev'
alias work '__tx work'
alias side '__tx side'

# One-time bootstrap for the work account:
#   CLAUDE_CONFIG_DIR=~/.claude-work claude
function claude --description 'Claude Code, config picked by tmux session'
    set -l session (tmux display-message -p '#S' 2>/dev/null)
    set -lx CLAUDE_CONFIG_DIR $HOME/.claude
    test "$session" = work; and set -lx CLAUDE_CONFIG_DIR $HOME/.claude-work
    command claude $argv
end

# mise is NOT activated here: /opt/homebrew/share/fish/vendor_conf.d/
# mise-activate.fish already does it and runs earlier. Activating twice cost
# ~20ms per shell and per prompt fork. To disable the vendor one:
# MISE_FISH_AUTO_ACTIVATE=0.

if command -q aws_completer
    complete -c aws -f -a "(env COMP_LINE=(commandline -pc) aws_completer | sed 's/ \$//')"
end

set -l docker_completion /Applications/Docker.app/Contents/Resources/etc/docker.fish-completion
test -f $docker_completion; and source $docker_completion

# Tide keeps its config in universal variables, which aren't versionable.
# install.sh seeds the base; these `set -g` shadow it (global beats universal)
# so the repo stays the source of truth. Hex values go without '#'.
set -g tide_left_prompt_items pwd git newline character
set -g tide_right_prompt_items status cmd_duration context jobs node bun go rustc python terraform aws docker time
set -g tide_prompt_add_newline_before true
set -g tide_prompt_transient_enabled true
set -g tide_cmd_duration_threshold 2000
set -g tide_time_format '%H:%M'
# 0 = don't truncate the branch name (Tide cuts at 24 by default).
set -g tide_git_truncation_length 0

# Icons go by CODEPOINT rather than pasting the glyph: Nerd Font glyphs live in
# the private use area and get lost when copied between editors or terminals,
# silently becoming an empty string.
# Catalog: nerdfonts.com/cheat-sheet · codepoint of a glyph: printf '%s' 'X' | xxd
set -g tide_git_icon (printf '\U0000F126')
# No pwd icon: the path speaks for itself.
# Set with no value (empty LIST, not empty string): in fish, concatenating an
# empty list with a string yields nothing, so Tide's `$tide_pwd_icon' '` doesn't
# leave a stray leading space.
set -g tide_pwd_icon
set -g tide_pwd_icon_home
set -g tide_pwd_icon_unwritable
set -g tide_cmd_duration_icon (printf '\U0000F252')
set -g tide_jobs_icon (printf '\U0000F013')
set -g tide_node_icon (printf '\U0000E24F')
set -g tide_bun_icon (printf '\U000F0CD3')
set -g tide_go_icon (printf '\U0000E627')
set -g tide_rustc_icon (printf '\U0000E7A8')
set -g tide_python_icon (printf '\U000F0320')
set -g tide_terraform_icon (printf '\U000F1062')
set -g tide_aws_icon (printf '\U0000E7AD')
set -g tide_docker_icon (printf '\U0000F308')

# Plain Unicode, not Nerd Font. Changes with the hybrid bindings' vi mode.
set -g tide_character_icon '❯'
set -g tide_character_vi_icon_default '❮'
set -g tide_character_vi_icon_replace '▶'
set -g tide_character_vi_icon_visual 'V'

# kanso-zen palette by role. The grey is kanso's bright-black #5C6066: against
# the #090E13 background that's 3.06:1, above the 3:1 floor for non-body text.
set -l muted 5C6066

set -g tide_pwd_color_dirs 8ba4b0
set -g tide_pwd_color_anchors 7aa89f
set -g tide_pwd_color_truncated_dirs $muted
set -g tide_git_color_branch 87a987
set -g tide_git_color_dirty e6c384
set -g tide_git_color_untracked 938aa9
set -g tide_git_color_conflicted e46876
set -g tide_git_color_staged 87a987
set -g tide_git_color_upstream 7aa89f
set -g tide_git_color_operation c4746e
set -g tide_git_color_stash 8ea4a2
set -g tide_character_color 87a987
set -g tide_character_color_failure e46876
set -g tide_cmd_duration_color 7aa89f
set -g tide_status_color 87a987
set -g tide_status_color_failure e46876
set -g tide_context_color_default $muted
set -g tide_context_color_ssh c4746e
set -g tide_context_color_root e46876
set -g tide_jobs_color 8ba4b0
set -g tide_aws_color e6c384
set -g tide_node_color 87a987
set -g tide_bun_color c5c9c7
set -g tide_go_color 7aa89f
set -g tide_rustc_color e46876
set -g tide_python_color e6c384
set -g tide_terraform_color 938aa9
set -g tide_docker_color 7aa89f
set -g tide_time_color $muted

set -g tide_prompt_color_frame_and_connection 22262D
set -g tide_prompt_color_separator_same_color $muted

# Tide's bun item only looks for `bun.lockb`, the binary lockfile Bun stopped
# writing by default in 1.2 — since then it's `bun.lock`.
function _tide_item_bun --description 'bun version, detecting bun.lock and bun.lockb'
    if path is $_tide_parent_dirs/bun.lock $_tide_parent_dirs/bun.lockb
        bun --version | string match -qr "(?<v>.*)"
        _tide_print_item bun $tide_bun_icon' ' $v
    end
end

# Same Bun change: markers are what paint a directory as a project root.
set -g tide_pwd_markers $tide_pwd_markers bun.lock

set -g tide_docker_default_contexts default desktop-linux

# Tide's item shells out to `docker context inspect`: 126ms of Go CLI startup to
# read something already in ~/.docker/config.json. Reading the file takes 69us.
# $DOCKER_CONTEXT wins over the file, which is docker's real precedence.
function _tide_item_docker --description 'docker context without invoking the CLI'
    set -l ctx $DOCKER_CONTEXT
    if test -z "$ctx"; and test -r $HOME/.docker/config.json
        set ctx (string match -rg '"currentContext"\s*:\s*"([^"]+)"' < $HOME/.docker/config.json)
    end
    test -z "$ctx"; and set ctx default
    contains -- $ctx $tide_docker_default_contexts; and return
    _tide_print_item docker $tide_docker_icon' ' $ctx
end

# tmux catches the bell: `monitor-bell on` turns the status bar orange.
set -g _notify_threshold 10000
set -g _notify_ignore nvim less man ssh tmux claude fzf watch top tail dev work side

function _notify_long_command --on-event fish_postexec --description 'Bell after a long command'
    test -n "$argv[1]"; or return
    set -l cmd (string split -f1 ' ' -- (string trim -- $argv[1]))
    contains -- $cmd $_notify_ignore; and return
    test $CMD_DURATION -ge $_notify_threshold; and printf '\a'
end

# Hybrid: emacs defaults plus vi mode on Esc. The binds live inside
# fish_user_key_bindings because fish calls it AFTER applying the defaults;
# loose, they'd be overwritten. Bound in insert and default to cover both sides.
function fish_user_key_bindings
    for mode in insert default
        # Ctrl-P/N: prefix history search. Costs Ctrl-N its
        # accept-autosuggestion, which stays on → or Ctrl-F.
        bind -M $mode ctrl-p up-or-search
        bind -M $mode ctrl-n down-or-search
        bind -M $mode ctrl-o edit_command_buffer
    end
end
set -g fish_key_bindings fish_hybrid_key_bindings

set -g fish_cursor_insert line blink
set -g fish_cursor_replace_one underscore
set -g fish_cursor_default block
set -g fish_cursor_visual block
# external is the cursor left while an external command runs. Beam, not block:
# apps that set their own override it anyway, but Claude Code inherits this one.
set -g fish_cursor_external line blink

if status is-interactive
    # Frees Ctrl-S/Ctrl-Q, which the terminal was swallowing.
    stty -ixon 2>/dev/null

    # Always explicit: ~/.aws/config has no [default] profile, so without this
    # every aws command outside the work session fails with NoCredentials.
    # Interactive only, so scripts and subshells don't inherit it.
    if test -n "$TMUX"; and test (tmux display-message -p '#S' 2>/dev/null) = work
        set -gx AWS_PROFILE work
    else
        set -gx AWS_PROFILE personal
    end

    if command -q zoxide
        zoxide init fish | source
    end

    if command -q fzf
        # ansi: bat uses the terminal palette, so previews match the theme.
        set -gx BAT_THEME ansi

        set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
        set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
        set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'

        # Ctrl-/ toggles preview, Ctrl-y copies the selection to the clipboard.
        set -gx FZF_DEFAULT_OPTS '
          --height 40% --layout=reverse --border=rounded
          --bind="ctrl-/:toggle-preview,ctrl-y:execute-silent(echo {} | pbcopy)+abort"
          --color=bg+:#5C6066,fg:#a4a7a4,fg+:#c5c9c7,hl:#7aa89f,hl+:#8ea4a2,info:#5C6066,prompt:#8ba4b0,pointer:#e46876,marker:#87a987,border:#5C6066,header:#8ba4b0,spinner:#8ea4a2'

        set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :200 {}'"
        set -gx FZF_ALT_C_OPTS "--preview 'ls -la {} | head -100'"
        set -gx FZF_CTRL_R_OPTS '--preview "echo {}" --preview-window=down:3:wrap'

        fzf --fish | source

        # Ctrl-L is a real control char (0x0c): works without the Kitty protocol
        # or extended keys. Overrides fish's clear-screen, which stays on cmd+k.
        for mode in insert default
            bind -M $mode ctrl-l fzf-history-widget
        end
    end
end
