vim.g.mapleader = " "

-- Everything is namespaced under lua/config/. Bare names would collide: Lua
-- preloads `debug`, so require("debug") returns the stdlib table and silently
-- never loads the file, and `ui`, `format` and `plugins` all exist as plugin
-- modules on the runtimepath.
--
-- vim.pack.add is synchronous, so every module after this one can require the
-- plugins it needs. Order is load-bearing twice: theme before ui, so lualine
-- reads a palette that exists; completion before lsp, so the servers are
-- registered with blink's capabilities rather than the stock ones.
require("config.plugins")

local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

opt.ignorecase = true
opt.smartcase = true

opt.guicursor = "n-v-c:block,i-ci-ve:ver25-blinkwait700-blinkon400-blinkoff250,r-cr-o:hor20"

opt.showmode = false
opt.laststatus = 3

opt.termguicolors = true
opt.cursorline = true
opt.colorcolumn = "100"
opt.scrolloff = 8
opt.wrap = false

opt.clipboard = "unnamedplus"

opt.splitright = true
opt.splitbelow = true

opt.swapfile = false
opt.undofile = true

opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- The LSP and completion stack writes here constantly; the default 4000ms makes
-- CursorHold-driven things feel broken.
opt.updatetime = 250
opt.signcolumn = "yes"

require("config.theme")
require("config.keymaps")
require("config.treesitter")
require("config.ui")
require("config.completion")
require("config.lsp")
require("config.format")
require("config.dap")
require("config.autocmds")
