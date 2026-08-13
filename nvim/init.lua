-- Before every require below, including config.plugins: the loader only caches
-- modules it sees loaded after this call.
vim.loader.enable()

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
opt.inccommand = "split"

opt.guicursor = "n-v-c:block,i-ci-ve:ver25-blinkwait700-blinkon400-blinkoff250,r-cr-o:hor20"

opt.showmode = false
opt.laststatus = 3

opt.termguicolors = true
-- Every float that does not ask for a border explicitly reads this: LSP hover,
-- diagnostics, blink's menu and docs. It is why vim.diagnostic.config no longer
-- sets one of its own.
opt.winborder = "rounded"
opt.cursorline = true
opt.colorcolumn = "100"
opt.scrolloff = 8
opt.wrap = false

opt.clipboard = "unnamedplus"

opt.splitright = true
opt.splitbelow = true

opt.swapfile = false
opt.undofile = true
opt.confirm = true

-- append, not set: the default "clean" is what drops jumplist entries for
-- buffers that no longer exist.
opt.jumpoptions:append("view")

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
require("config.git")
require("config.completion")
require("config.lsp")
require("config.format")
require("config.dap")
require("config.markdown")
require("config.autocmds")
