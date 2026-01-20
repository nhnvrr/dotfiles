# Core ZSH Settings
setopt auto_cd hist_ignore_all_dups share_history
setopt extended_glob interactive_comments

# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Completion system
autoload -Uz compinit
compinit -C
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select

# Essential Aliases
# Core commands
alias ls="eza"
alias ll="ls -la"
alias l="ll"
alias la="ls -la"
alias cl="clear"
alias grep="grep --color=auto"

# Safe operations
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

# Git essentials
alias gst="git status"
alias gc="git commit -m"
alias gp="git push origin HEAD"
alias gco="git checkout"
alias ga="git add"

# HTTP client
alias http="xh"

# Network scanning
alias nm="nmap -sC -sV -oN nmap"

# My Personal Scripts
alias lg="lazygit"
alias b="bun run"
alias ts="npx tsx --env.file=.env "
alias serve="python3 -m http.server"

# Environment Variables
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=/opt/homebrew/bin/nvim
export VISUAL=/opt/homebrew/bin/nvim

# Path Configuration
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

# Vi-mode Configuration
bindkey -v
export KEYTIMEOUT=1

# Fix backspace and other keys in insert mode
bindkey -v '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^r' history-incremental-search-backward

# Better cursor shape for different vi modes
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'  # Block cursor for normal mode
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'  # Beam cursor for insert mode
  fi
}
zle -N zle-keymap-select

# Use beam shape cursor on startup and for each new prompt
echo -ne '\e[5 q'
preexec() { echo -ne '\e[5 q' ;}

# ZSH Plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Keybindings for autosuggestions
bindkey '^e' autosuggest-accept
bindkey '^u' autosuggest-toggle
bindkey '^w' autosuggest-execute

# Atuin - Shell history with sync (MUST be last, after vi-mode)
eval "$(atuin init zsh)"
