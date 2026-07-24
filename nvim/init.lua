-- nvim: editor de apoyo, no IDE.
-- Se usa como $EDITOR/$VISUAL (mensajes de commit, `git rebase -i`), como
-- Ctrl-O de fish (editar la línea de comando) y para ediciones sueltas.
-- El laburo diario es en VS Code, así que acá no hay LSP, ni completion, ni
-- treesitter, ni DAP, ni file explorer: eso eran ~800 líneas y 900 MB de
-- language servers para un editor que se abre unas pocas veces al mes.
--
-- Único plugin: el theme, para no desentonar con Ghostty/fzf/Tide.

vim.g.mapleader = " "

-- ─── Theme ──────────────────────────────────────────────
-- kanso (variante Zen), el mismo que Ghostty. transparent = true ⇒ el fondo lo
-- pone el terminal, así que nvim hereda el #090E13 de kanso-zen sin fijarlo.
vim.pack.add({ "https://github.com/webhooked/kanso.nvim" })
require("kanso").setup({ transparent = true, theme = "zen" })
vim.o.background = "dark"
vim.cmd.colorscheme("kanso-zen")

-- ─── Options ────────────────────────────────────────────
local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

opt.ignorecase = true
opt.smartcase = true

-- Cursor: beam parpadeante en TODOS los modos. El default de nvim es
-- `n-v-c-sm:block,i-ci-ve:ver25,...` — o sea bloque en normal/visual/command,
-- que pisaba el beam configurado en Ghostty y en tmux. `a:` aplica a todo.
opt.guicursor = "a:ver25-blinkwait700-blinkon400-blinkoff250"

opt.termguicolors = true
opt.cursorline = true
opt.colorcolumn = "100"
opt.scrolloff = 8
opt.wrap = false

-- Clipboard del sistema por defecto: yank en nvim = pegar en cualquier app.
opt.clipboard = "unnamedplus"

opt.splitright = true
opt.splitbelow = true

-- Sin swap, pero con undo persistente: cerrar y reabrir un archivo conserva
-- el historial de deshacer.
opt.swapfile = false
opt.undofile = true

-- Whitespace visible: tabs, espacios al final de línea, nbsp.
opt.list = true
opt.listchars = { tab = "▸ ", trail = "·", nbsp = "␣" }

-- ─── Keymaps ────────────────────────────────────────────
-- Typos habituales al guardar/salir con Shift apretado de más.
vim.api.nvim_create_user_command("W", "w", {})
vim.api.nvim_create_user_command("Q", "q", {})
vim.api.nvim_create_user_command("Wq", "wq", {})
vim.api.nvim_create_user_command("WQ", "wq", {})

vim.keymap.set("i", "jk", "<Esc>", { desc = "Salir de insert" })
vim.keymap.set("n", "<leader>nh", "<cmd>nohlsearch<cr>", { desc = "Limpiar highlight de búsqueda" })

-- ─── Explorador de archivos ─────────────────────────────
-- netrw, que ya viene con nvim: cero plugins. neo-tree necesitaría cuatro
-- (neo-tree + plenary + nui + devicons) y nvim-tree dos.
--   liststyle 3  vista de árbol en vez de lista plana
--   banner 0     sin el cartel de ayuda de 6 líneas arriba
--   winsize 25   ancho del sidebar, en % de la ventana
-- `:Lexplore` es toggle: la misma tecla abre y cierra.
-- Adentro: <CR> abre, `-` sube un nivel, `%` archivo nuevo, `d` directorio,
-- `D` borra, `R` renombra, `i` cicla vistas.
vim.g.netrw_liststyle = 3
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
vim.keymap.set("n", "<leader>e", "<cmd>Lexplore<cr>", { desc = "Explorador de archivos" })

-- ─── Autocmds ───────────────────────────────────────────
-- Flash sobre el texto copiado: confirma qué entró al yank sin tener que mirar.
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

-- Reabrir un archivo deja el cursor donde estaba.
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- `q` cierra los buffers de solo lectura en vez de tener que hacer :q.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "help", "man", "qf", "checkhealth" },
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true })
  end,
})
