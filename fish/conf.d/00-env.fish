# Must keep the 00- prefix and stay out of config.fish: fish sources conf.d
# sorted by name, and mise's vendor snippet prepends to whatever $PATH it finds.
# Run this after it and a stray ~/.bun/bin shadows the mise-pinned runtime.

# fish never runs /usr/libexec/path_helper, so there is no base PATH to inherit
# — everything below has to be explicit.
set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
set -gx HOMEBREW_REPOSITORY /opt/homebrew

# INFOPATH is inherited and this runs in nested shells too: without the guard
# it grows one copy per shell.
contains -- /opt/homebrew/share/info $INFOPATH
or set -gx INFOPATH /opt/homebrew/share/info $INFOPATH

# LANG only: LC_ALL overrides every LC_* category and blocks per-category tweaks.
set -gx LANG en_US.UTF-8
set -gx EDITOR nvim
set -gx VISUAL nvim

set -gx GOPATH $HOME/Develop/go
set -gx GOPRIVATE github.com/nhnvrr
set -gx PNPM_HOME $HOME/Library/pnpm

# -g, not -U: $fish_user_paths is state outside the repo and drifts.
fish_add_path -g $GOPATH/bin /opt/homebrew/bin /opt/homebrew/sbin \
    /opt/homebrew/opt/libpq/bin $HOME/.bun/bin $HOME/.local/bin \
    $PNPM_HOME/bin /usr/local/bin
