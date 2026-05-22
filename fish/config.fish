# Locale and editor settings.
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8
set -gx EDITOR nvim
set -gx VISUAL nvim

set -g fish_greeting

# PATH (fish_add_path dedupes and prepends).
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin
fish_add_path /opt/homebrew/opt/libpq/bin
fish_add_path /usr/local/bin
fish_add_path $HOME/.local/bin

# Go workspace.
set -gx GOPATH $HOME/Develop/go
set -gx GOPRIVATE github.com/nhnvrr
fish_add_path $GOPATH/bin

# Aliases (terse names).
alias ll "ls -l"
alias l  "ll"
alias la "ls -la"
alias cl "clear"
alias code "code --new-window"

# tmux: open or create a named session (switch if already inside tmux).
function __tx --argument-names name
    set -l dir
    switch $name
        case dev;    set dir $HOME/develop
        case vesto;  set dir $HOME/vesto
        case spexs;  set dir $HOME/spexs/spexs-ai
        case '*'
            echo "__tx: unknown session '$name'" >&2
            return 1
    end

    if not tmux has-session -t=$name 2>/dev/null
        tmux new-session -d -s $name -c $dir
    end

    if test -z "$TMUX"
        tmux attach-session -t $name
    else
        tmux switch-client -t $name
    end
end

alias dev   "__tx dev"
alias vesto "__tx vesto"
alias spexs "__tx spexs"

# Git abbreviations (expand visually so you see the underlying command).
abbr -a gst "git status -sb"
abbr -a gc  "git commit -m"
abbr -a gp  "git push origin HEAD"
abbr -a gco "git checkout"
abbr -a ga  "git add"

# AWS CLI completion.
if command -q aws_completer
    complete -c aws -f -a "(env COMP_LINE=(commandline -pc) aws_completer | sed 's/ \$//')"
end

# Tool/runtime version manager.
if command -q mise
    mise activate fish | source
end

# Interactive-only setup.
if status is-interactive
    # Hybrid key bindings: defaults emacs (Ctrl+A/E/W/U/K/R, Alt+B/F) +
    # vi mode disponible apretando Esc. Sin perder muscle memory, ganás
    # navegación vi (h/j/k/l, w/b, /, ?, v, y) sobre comandos largos.
    fish_hybrid_key_bindings

    # Let Ctrl-S/Ctrl-Q reach the shell instead of being eaten by the terminal.
    stty -ixon 2>/dev/null

    # Keep Ctrl-P/Ctrl-N for prefix history search (muscle memory from zsh).
    bind \cp up-or-search
    bind \cn down-or-search

    # Ctrl-O: edit current command line in $EDITOR (nvim).
    bind \co edit_command_buffer

    if command -q starship
        starship init fish | source
    end

    # fzf key bindings: Ctrl-R history, Ctrl-T files, Alt-C dirs.
    if test -f /opt/homebrew/opt/fzf/shell/key-bindings.fish
        source /opt/homebrew/opt/fzf/shell/key-bindings.fish
        fzf_key_bindings
    end
end
