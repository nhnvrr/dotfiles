vim.g.mapleader = " "
local opt = vim.opt

-- line numbers
opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

opt.wrap = false

-- search
opt.ignorecase = true
opt.smartcase = true

-- appearance
opt.cursorline = true
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.colorcolumn = "100"
opt.scrolloff = 8 -- mantener 8 líneas de contexto arriba/abajo del cursor

-- folding (treesitter, vía la API del core → independiente del plugin)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevelstart = 99 -- abrir todo por defecto; nada colapsado al abrir un archivo
opt.fillchars = { horiz = "─", horizup = "┴", horizdown = "┬", vert = "│", vertleft = "┤", vertright = "├", verthoriz = "┼" }

-- completion (native 0.12)
opt.autocomplete = true
opt.pumborder = "rounded"
opt.pummaxwidth = 40
opt.completeopt = "menu,menuone,noselect,fuzzy,popup"

-- backspace
opt.backspace = "indent,eol,start"

-- clipboard
opt.clipboard = "unnamedplus"

-- splits
opt.splitright = true
opt.splitbelow = true

-- no swap
opt.swapfile = false

-- undo persistente entre sesiones (sobrevive al cierre de nvim)
opt.undofile = true

-- disable horizontal scrolling
opt.sidescroll = 0
opt.sidescrolloff = 0

-- visible whitespace
opt.list = true
opt.listchars = {
  tab = "▸ ",
  trail = "·",
  extends = "»",
  precedes = "«",
  nbsp = "␣",
}
