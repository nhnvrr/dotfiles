# Core ZSH Settings
setopt auto_cd hist_ignore_all_dups share_history
setopt extended_glob interactive_comments
unsetopt xtrace verbose

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
alias '?'="ollama run llama3.2"

# Environment Variables
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=/opt/homebrew/bin/nvim
export VISUAL=/opt/homebrew/bin/nvim
export BAT_THEME=Nord

# Path Configuration
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

# ZSH Plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

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

# Nord Aurora syntax highlighting (keep zsh-syntax-highlighting last)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#4c566a"
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[comment]="fg=#4c566a"
ZSH_HIGHLIGHT_STYLES[command]="fg=#a3be8c"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#a3be8c"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#a3be8c"
ZSH_HIGHLIGHT_STYLES[function]="fg=#a3be8c"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#ebcb8b"
ZSH_HIGHLIGHT_STYLES[precommand]="fg=#b48ead"
ZSH_HIGHLIGHT_STYLES[commandseparator]="fg=#4c566a"
ZSH_HIGHLIGHT_STYLES[redirection]="fg=#b48ead"
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg=#d08770"
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg=#d08770"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#ebcb8b"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#ebcb8b"
ZSH_HIGHLIGHT_STYLES[path]="fg=#a3be8c"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#ebcb8b"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#bf616a"
ZSH_HIGHLIGHT_STYLES[error]="fg=#bf616a,bold"
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
