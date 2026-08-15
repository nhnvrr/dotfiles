brew "fish"
brew "starship"

# Not a shell multiplexer: Ghostty tabs already do that. It reads agent
# state off the CLIs over a socket API, which is what no tab bar can show.
brew "herdr"

# Neovim uses only native features. Language servers provide completion and
# validation; the formatter binaries run directly before each write.
brew "neovim"
brew "vtsls"
brew "gopls"
brew "rust-analyzer"
brew "bash-language-server"
brew "yaml-language-server"
brew "vscode-langservers-extracted"
brew "prettier"
brew "gofumpt"
brew "shfmt"

# fd and bat are not optional extras next to fzf: config.fish wires
# FZF_DEFAULT_COMMAND and the Ctrl-T preview straight to them.
brew "fzf"
brew "fd"
brew "bat"
# Declared for nvim's fzf-lua live_grep. Undeclared it still resolves, but only
# to a copy vendored inside an editor extension, which leaves and breaks grep.
brew "ripgrep"
brew "jq"

# ls replacement. Not for the colours — coreutils ls already does those — but
# for the two columns it cannot draw at all: --git, the per-file status against
# the index, and the Nerd Font icons. Themed by ANSI name in eza/theme.yml.
brew "eza"

brew "git"
brew "gh"
brew "git-delta"
brew "lazygit"

brew "libpq"
# Here for redis-cli, the scriptable client.
brew "redis"
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

cask "ghostty"
cask "font-monaspice-nerd-font"

cask "visual-studio-code"
cask "zed"

# Clipboard history. Maccy is MIT, native, and the cask pulls from the
# project's own GitHub releases — there are typosquat "maccy" sites.
# Needs Accessibility permission on first launch or paste-on-select does nothing.
cask "maccy"

# The default handler.
cask "google-chrome"
cask "zen"

cask "docker-desktop"
cask "datagrip"
cask "bruno"

cask "aws-vpn-client"

cask "claude-code@latest"
cask "claude"
cask "chatgpt"
cask "codex"

cask "cap"

cask "slack"
cask "gather"
cask "telegram"

cask "ledger-wallet"
cask "nordvpn"
