brew "fish"
brew "starship"

# The only multiplexer, and not one for shells alone: it reads agent state off
# the CLIs over a socket API, which is the job tmux could not do and what it
# was replaced with.
brew "herdr"
brew "neovim"
# Language servers for nvim. All of them come from here rather than Mason, which
# is only pulled in for the two debug adapters Homebrew doesn't carry.
# vscode-langservers-extracted is the one that isn't obvious: it provides both
# vscode-eslint-language-server and vscode-json-language-server.
brew "vtsls"
brew "vscode-langservers-extracted"
brew "yaml-language-server"
brew "prettier"
# Also shipped by rustup and by mise's Go, whichever lands first on $PATH. They
# are declared anyway so a fresh machine gets them from `brew bundle` alone.
brew "rust-analyzer"
brew "gopls"
# tree-sitter-cli is what nvim-treesitter's main branch shells out to when a
# parser is missing.
brew "tree-sitter-cli"

brew "fzf"
brew "fd"
brew "ripgrep"
brew "bat"
brew "jq"
brew "zoxide"
brew "eza"

brew "git"
brew "gh"
brew "git-delta"
brew "lazygit"
brew "lazydocker"

brew "libpq"
brew "pgcli"
# redis is here for redis-cli, the scriptable fallback; iredis is the
# interactive one, same split as psql/pgcli.
brew "redis"
brew "iredis"
# Nothing in Homebrew depends on this, so it reads as an orphan leaf, but the odbc
# npm package links its native binding against libodbc; ~/side's ETL needs it.
brew "unixodbc"
brew "mise"

brew "cocoapods"
brew "watchman"

brew "sentry-cli"
brew "delve"

brew "yt-dlp"
brew "ffmpeg"
brew "btop"
brew "fastfetch"

# The cask also symlinks the alacritty terminfo into ~/.terminfo, which is why
# install.sh has no terminfo step: `brew bundle` is what makes TERM=alacritty
# resolve, and the entry is not in the system database.
cask "alacritty"
cask "font-monaspice-nerd-font"

cask "visual-studio-code"

cask "hammerspoon"

cask "helium-browser"

cask "docker-desktop"
cask "tableplus"
cask "bruno"
cask "proxyman"
cask "utm"

cask "aws-vpn-client"

cask "claude"
cask "claude-code@latest"
cask "chatgpt"
cask "codex"

cask "cap"
cask "linear"
cask "notion"

cask "slack"
cask "gather"
cask "whatsapp"
cask "telegram"

cask "ledger-wallet"
cask "nordvpn"
