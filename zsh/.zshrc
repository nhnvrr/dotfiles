# Core Zsh Settings
bindkey -e
setopt extendedhistory
setopt autocd
setopt interactivecomments
setopt noclobber
setopt completeinword
setopt nobeep
setopt auto_pushd
setopt pushdignoredups
setopt pushdminus
setopt histignoredups
setopt histignorealldups
setopt histsavenodups
setopt histfindnodups
setopt histverify
setopt histignorespace
setopt histreduceblanks
setopt sharehistory
setopt incappendhistory

# History configuration
HISTSIZE=20000
SAVEHIST=20000
HISTFILE="$HOME/.zsh_history"
HIST_STAMPS="yyyy-mm-dd"
KEYTIMEOUT=1

if [[ -o interactive ]]; then
  # Keybindings (history search)
  bindkey '^P' up-line-or-history
  bindkey '^N' down-line-or-history
  bindkey '^R' history-incremental-search-backward
  bindkey '^S' history-incremental-search-forward
  bindkey '^[[A' history-search-backward
  bindkey '^[[B' history-search-forward

  # Let Ctrl-S/Ctrl-Q work in tmux and zsh keybindings.
  stty -ixon 2>/dev/null
fi

# Environment Variables
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=nvim
export VISUAL=nvim

# Path Configuration
typeset -U path PATH
path=(
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /usr/local/bin
  "$HOME/.local/bin"
  $path
)
export PATH

# Completion (interactive only)
if [[ -o interactive ]]; then
  autoload -Uz compinit
  if [[ -n "${XDG_CACHE_HOME:-}" ]]; then
    compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
  else
    compinit
  fi
  zmodload -i zsh/complist
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
  zstyle ':completion:*' list-colors ''
fi

# Essential Aliases
alias ll="ls -l"
alias l="ll"
alias la="ls -la"
alias cl="clear"
alias grep="grep --color=auto"

# Git essentials
alias gst="git status -sb"
alias gc="git commit -m"
alias gp="git push origin HEAD"
alias gco="git checkout"
alias ga="git add"

# Prompt (interactive only)
if [[ -o interactive ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# bun completions
[ -s "/Users/nhnvrr/.bun/_bun" ] && source "/Users/nhnvrr/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
