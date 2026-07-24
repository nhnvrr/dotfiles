# Fuente de verdad de las herramientas de la máquina.
# `brew bundle cleanup --force` desinstala TODO lo que no esté declarado acá,
# así que agregar algo a mano con `brew install` y no anotarlo = perderlo.
#
# Los runtimes (node, go, rust, python, terraform, bun, aws-cli) NO van acá:
# los gestiona mise por proyecto — ver mise/config.toml.

# ─── Terminal ───────────────────────────────────────────
brew "fish"
brew "tmux"
# nvim es solo $EDITOR (commits, Ctrl-O de fish, ediciones sueltas): un
# init.lua de ~90 líneas con un plugin. Sin treesitter, ni CLI de tree-sitter.
brew "neovim"

# ─── Búsqueda y lectura ─────────────────────────────────
# fzf, fd y ripgrep no se tipean casi nunca: fd y rg son los motores de fzf
# (Ctrl-T/Alt-C) y fzf corre desde keybindings. Medir su uso por historial da
# 0 y engaña.
brew "fzf"
brew "fd"
brew "ripgrep"
brew "bat"
brew "jq"

# ─── Git ────────────────────────────────────────────────
brew "git"
brew "gh"

# ─── Base de datos ──────────────────────────────────────
# libpq trae psql (el cliente) sin el servidor de Postgres. El camino
# principal para DB es la terminal; TablePlus queda como complemento visual.
brew "libpq"

# ─── Runtimes ───────────────────────────────────────────
brew "mise"

# ─── Utilidades ─────────────────────────────────────────
brew "yt-dlp"
brew "htop"
brew "fastfetch"

# ─── Terminal y fuente ──────────────────────────────────
cask "ghostty"
cask "font-geist-mono-nerd-font"

# ─── Editor ─────────────────────────────────────────────
# VS Code se queda hasta confirmar que AWS Toolkit y Remote-SSH funcionan en
# Cursor: Cursor usa Open VSX como marketplace y AWS Toolkit no está publicado
# ahí. Ese es el motivo por el que se eligió VS Code en su momento.
cask "cursor"
cask "visual-studio-code"

# ─── Ventanas y lanzador ────────────────────────────────
# Raycast cubre lanzador, clipboard, snippets y ventanas simples. Hammerspoon
# se queda por los layouts de apps pareadas (⌘⌥1/2/3), que Raycast no hace.
cask "raycast"
cask "hammerspoon"

# ─── Navegador ──────────────────────────────────────────
cask "google-chrome"

# ─── Desarrollo ─────────────────────────────────────────
cask "docker-desktop"
cask "tableplus"
cask "bruno"
cask "proxyman"

# ─── AWS ────────────────────────────────────────────────
cask "aws-vpn-client"

# ─── IA ─────────────────────────────────────────────────
cask "claude"
cask "claude-code@latest"
cask "chatgpt"

# ─── Notas y captura ────────────────────────────────────
# Obsidian es la herramienta principal de notas. Linear y Notion se usan
# desde la web.
cask "obsidian"
cask "cap"

# ─── Comunicación ───────────────────────────────────────
cask "slack"
cask "whatsapp"

# ─── Otros ──────────────────────────────────────────────
cask "ledger-wallet"
cask "nordvpn"
