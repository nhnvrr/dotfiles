tap "getsentry/tools"

brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

brew "herdr"

brew "neovim"
brew "vtsls"
brew "gopls"
brew "rust-analyzer"
brew "bash-language-server"
brew "yaml-language-server"
brew "vscode-langservers-extracted"
# The config is ~1200 lines of Lua that edits itself; without a server a typo in
# an API name is found by restarting nvim and reading a traceback.
brew "lua-language-server"
# Three TOML files here drive alacritty, mise and herdr. A misspelled
# key in any of them is otherwise discovered by the program behaving oddly.
brew "taplo"

brew "prettier"
brew "gofumpt"
brew "shfmt"
brew "stylua"

# Nothing calls this by hand: bash-language-server runs it itself as soon as the
# binary is on PATH, which is the whole reason it is declared here rather than
# wired up in the editor.
brew "shellcheck"
# The linter gopls is not — gopls reports type errors, this reports the rest.
# nvim-lint is what feeds it into the diagnostics list.
brew "golangci-lint"

# Required by nvim-treesitter's `main` branch to compile parsers, together with
# a C compiler. It must be this build and NOT the npm package of the same name:
# that one is a different program and cannot generate the parsers.
brew "tree-sitter-cli"

brew "fzf"
brew "fd"
brew "bat"
brew "ripgrep"
brew "jq"

brew "eza"

brew "git"
brew "gh"
brew "git-delta"
brew "lazygit"

brew "libpq"
brew "redis"
# Nothing Homebrew can see depends on this, which makes it look removable. It is
# not: it was installed for the reconciliation work in vesto, and ODBC drivers
# dlopen libodbc.2.dylib at runtime, where `brew uses` cannot follow.
brew "unixodbc"
brew "mise"

# Both for ~/work/vesto-react-native, and neither shows up in shell history:
# `pod install` runs when the iOS deps change, watchman is started by Metro
# rather than by hand. Absence from history is not evidence here.
brew "cocoapods"
brew "watchman"

brew "getsentry/tools/sentry"
# The Go debugger. Two Go repos live under ~/Develop, both occasional — this is
# the one line here that would survive being cut, kept because it is 20MB and
# reinstalling it mid-debug is the wrong moment to find out.
brew "delve"

brew "yt-dlp"
brew "ffmpeg"
brew "btop"

# Alacritty is the terminal. Its config is a plain TOML file at
# ~/.config/alacritty/alacritty.toml, which is what install.sh symlinks and what
# carries the sixteen ANSI slots the rest of the stack resolves through.
#
# Homebrew deprecated this cask on 2026-08 for failing the macOS Gatekeeper
# check and disables it on 2026-09-01. An already-installed Alacritty keeps
# working; a fresh machine after that date needs `cargo install alacritty` or
# the signed build from the project's own releases.
cask "alacritty"

cask "font-jetbrains-mono-nerd-font"

cask "visual-studio-code"
cask "maccy"
cask "hammerspoon"
# The browser and the default handler. The Claude in Chrome extension ships only
# through the Chrome Web Store and has no equivalent elsewhere, which is what
# settles it between two Chromium builds.
cask "google-chrome"
# No longer the default — Chrome is. Kept as a second browser for the profile
# separation, and because the cask name matters: plain `helium` is a different
# application entirely (koush's), deprecated for failing the Gatekeeper check —
# the same trap alacritty is in above. Still 0.x and it auto-updates outside
# Homebrew. Undeclared it would be removed by `brew bundle cleanup`.
cask "helium-browser"
cask "docker-desktop"
# The only database GUI left standing, now that TablePlus is uninstalled. It is
# also the one with the JetBrains keymap the rest of the toolchain already uses.
cask "datagrip"
cask "bruno"
# Two API clients on purpose, same as Chrome and Brave: Postman for the shared
# collections a team already lives in, Bruno for the ones that belong in a repo.
cask "postman"

cask "aws-vpn-client"

cask "claude-code@latest"
cask "claude"
cask "chatgpt"
cask "codex"

cask "cap"

cask "notion"
cask "slack"
cask "gather"
cask "telegram"

cask "ledger-wallet"
cask "nordvpn"
