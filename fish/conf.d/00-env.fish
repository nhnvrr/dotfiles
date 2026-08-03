# Named 00- and kept out of config.fish on purpose: fish sources every conf.d
# snippet sorted by name, vendor ones included, and config.fish only after all
# of them. mise's vendor snippet prepends its installs to whatever $PATH it
# finds, so this has to run *before* it or a stray ~/.bun/bin shadows the
# mise-pinned runtime. Same ordering the old zprofile → zshrc pair had.

# brew shellenv inlined as constants: the eval is 2 forks (~20ms) to print what
# never changes. fish never runs /usr/libexec/path_helper, so unlike zsh there
# is no base PATH to inherit — everything below has to be explicit.
set -gx HOMEBREW_PREFIX /opt/homebrew
set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
set -gx HOMEBREW_REPOSITORY /opt/homebrew

# Guarded: this runs in every fish, nested ones included, and INFOPATH is
# inherited — without the check it grows one copy per shell.
contains -- /opt/homebrew/share/info $INFOPATH
or set -gx INFOPATH /opt/homebrew/share/info $INFOPATH

# LANG only: LC_ALL overrides every LC_* category and blocks per-category tweaks.
set -gx LANG en_US.UTF-8
set -gx EDITOR nvim
set -gx VISUAL nvim

set -gx GOPATH $HOME/Develop/go
set -gx GOPRIVATE github.com/nhnvrr
set -gx PNPM_HOME $HOME/Library/pnpm

# -g, not -U: $fish_user_paths is state outside the repo and drifts. Order given
# is order of precedence. Directories that don't exist yet are skipped, and
# picked up by the next shell once they appear.
fish_add_path -g $GOPATH/bin /opt/homebrew/bin /opt/homebrew/sbin \
    /opt/homebrew/opt/libpq/bin $HOME/.bun/bin $HOME/.local/bin \
    $PNPM_HOME/bin /usr/local/bin
