# Locale and editor settings.
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8
set -gx EDITOR nvim
set -gx VISUAL nvim

# Keep common bin directories near the front of PATH.
fish_add_path -m /opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin $HOME/.local/bin

# Essential aliases
alias ll "ls -l"
alias l "ll"
alias la "ls -la"
alias cl "clear"
alias grep "grep --color=auto"

# Git essentials
alias gst "git status -sb"
alias gc "git commit -m"
alias gp "git push origin HEAD"
alias gco "git checkout"
alias ga "git add"
alias lg "lazygit"

# bun
set -gx BUN_INSTALL $HOME/.bun
fish_add_path -m $BUN_INSTALL/bin

# nvm location (nvm.sh itself is bash/zsh-targeted)
set -gx NVM_DIR $HOME/.nvm

if status is-interactive
    # Let Ctrl-S/Ctrl-Q work in tmux and fish keybindings.
    stty -ixon 2>/dev/null

    # Keybindings close to the current zsh setup.
    bind \cp up-or-search
    bind \cn down-or-search
    bind \cr history-pager
    bind \cs history-pager

    if command -q starship
        starship init fish | source
    end

    if command -q bun
        bun completions fish | source
    end
end
