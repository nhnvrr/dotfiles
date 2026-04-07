vim.g.mapleader = " "
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

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
opt.cmdheight = 1
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.colorcolumn = "100"
opt.fillchars = { horiz = "─", horizup = "┴", horizdown = "┬", vert = "│", vertleft = "┤", vertright = "├", verthoriz = "┼" }

-- completion (native 0.12)
opt.autocomplete = true
opt.pumborder = "rounded"
opt.pummaxwidth = 40
opt.completeopt = "menu,menuone,noselect,nearest"

-- backspace
opt.backspace = "indent,eol,start"

-- clipboard
opt.clipboard:append("unnamedplus")

-- splits
opt.splitright = true
opt.splitbelow = true

-- no swap
opt.swapfile = false

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
