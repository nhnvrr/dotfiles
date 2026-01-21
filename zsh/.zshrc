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
alias ll="ls -l"
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

# Network scanning
alias nm="nmap -sC -sV -oN nmap"

# My Personal Scripts
alias b="bun run"
alias ts="npx tsx --env.file=.env "
alias serve="python3 -m http.server"

# Environment Variables
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=/opt/homebrew/bin/nvim
export VISUAL=/opt/homebrew/bin/nvim
export BAT_THEME=Nord

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

# Pastel dark syntax highlighting
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086"
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]="fg=#6c7086"
ZSH_HIGHLIGHT_STYLES[command]="fg=#a6e3a1"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#a6e3a1"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#a6e3a1"
ZSH_HIGHLIGHT_STYLES[function]="fg=#a6e3a1"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#f9e2af"
ZSH_HIGHLIGHT_STYLES[precommand]="fg=#89b4fa"
ZSH_HIGHLIGHT_STYLES[commandseparator]="fg=#bac2de"
ZSH_HIGHLIGHT_STYLES[redirection]="fg=#89b4fa"
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg=#fab387"
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg=#fab387"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#94e2d5"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#94e2d5"
ZSH_HIGHLIGHT_STYLES[path]="fg=#89b4fa"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#f9e2af"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#f38ba8"
ZSH_HIGHLIGHT_STYLES[error]="fg=#f38ba8,bold"

# Keybindings for autosuggestions
bindkey '^e' autosuggest-accept
bindkey '^u' autosuggest-toggle
bindkey '^w' autosuggest-execute

# Starship prompt
eval "$(starship init zsh)"

# Atuin - Shell history with sync (MUST be last, after vi-mode)
eval "$(atuin init zsh)"

# bun completions
[ -s "/Users/nhnvrr/.bun/_bun" ] && source "/Users/nhnvrr/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
