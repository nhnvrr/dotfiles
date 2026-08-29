tap "getsentry/tools"

brew "fish"

brew "herdr"
# Not a second copy of the line above. herdr supervises agents over a socket API
# and dies with the terminal that started it; tmux is what holds a session
# across an ssh disconnect and the only one of the two that exists on a remote
# host. Read as alternatives they look redundant, and `brew bundle cleanup`
# would take this one out.
brew "tmux"
# tmux's plugin manager, and the only reason it is a package instead of a clone
# in install.sh. It is what pulls resurrect and continuum, which are what make a
# session — and its scrollback — survive a reboot rather than just a disconnect.
brew "tpm"

brew "neovim"
brew "vtsls"
brew "gopls"
brew "rust-analyzer"
brew "yaml-language-server"
brew "vscode-langservers-extracted"
brew "prettier"
brew "gofumpt"
brew "shfmt"
brew "stylua"
brew "taplo"
brew "lua-language-server"
brew "bash-language-server"
brew "shellcheck"
brew "golangci-lint"
brew "tree-sitter-cli"

brew "fzf"
brew "fd"
brew "bat"
brew "ripgrep"
brew "jq"
brew "eza"
brew "duti"

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

# The terminal; ghostty/config carries the sixteen ANSI slots the rest of the
# stack resolves through.
cask "ghostty"
# Glyph fallback for the fish prompt; ghostty/config lists it after the main face.
cask "font-symbols-only-nerd-font"

cask "visual-studio-code"
cask "maccy"
cask "hammerspoon"
# The browser and the default handler, and the only one here. The Claude in
# Chrome extension ships solely through the Chrome Web Store and has no
# equivalent elsewhere, which is what settles it against any other Chromium
# build.
cask "google-chrome"
cask "docker-desktop"
# The only database GUI left standing, now that TablePlus is uninstalled. It is
# also the one with the JetBrains keymap the rest of the toolchain already uses.
cask "datagrip"
cask "bruno"

cask "aws-vpn-client"

cask "claude-code@latest"
cask "claude"
cask "chatgpt"
cask "codex"

cask "cap"

cask "slack"
cask "discord"
cask "telegram"
cask "granola"

cask "ledger-wallet"
