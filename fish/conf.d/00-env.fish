# 00- prefix is load-bearing: conf.d is sourced by name and Homebrew's
# vendor_conf.d/mise-activate.fish prepends to whatever $PATH it finds, so this
# has to run first or ~/.bun/bin shadows the mise-pinned runtime.

set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
set -gx HOMEBREW_REPOSITORY /opt/homebrew

contains -- /opt/homebrew/share/info $INFOPATH
or set -gx INFOPATH /opt/homebrew/share/info $INFOPATH

set -gx LANG en_US.UTF-8
# --wait, or git reads the still-empty buffer and aborts the commit.
set -gx EDITOR "code --wait"
set -gx VISUAL "code --wait"

set -gx GOPATH $HOME/Develop/go
set -gx GOPRIVATE github.com/nhnvrr
set -gx PNPM_HOME $HOME/Library/pnpm

set -gx AWS_PAGER ""
set -gx AWS_RETRY_MODE standard
set -gx AWS_MAX_ATTEMPTS 3

set -gx REDISCLI_HISTFILE $HOME/.local/state/redis/history
set -gx BAT_THEME ansi
set -gx EZA_CONFIG_DIR $HOME/.config/eza

fish_add_path -g $GOPATH/bin /opt/homebrew/bin /opt/homebrew/sbin \
    /opt/homebrew/opt/libpq/bin $HOME/.bun/bin $HOME/.local/bin \
    $PNPM_HOME/bin /usr/local/bin
