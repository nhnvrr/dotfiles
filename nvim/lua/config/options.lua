-- Builtin plugins this profile never reaches. They are sourced from $VIMRUNTIME
-- during startup unless the flag is set BEFORE it, which is why this module is
-- the first one init.lua requires. netrw is the one that matters: neo-tree
-- replaces it outright, and left enabled it still registers its autocmds and
-- hijacks a `:e directory/`.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_spellfile_plugin = 1
-- The variable runtime/plugin/rplugin.vim actually checks. `loaded_rplugin`,
-- which reads like the right name, is not read by anything and left the remote
-- plugin manifest loading on every start.
vim.g.loaded_remote_plugins = 1

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

local opt = vim.opt

opt.number = true
opt.signcolumn = "yes"
opt.wrap = false
opt.scrolloff = 4
-- lualine already draws the mode; the builtin message would print it twice.
opt.showmode = false

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

opt.ignorecase = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true

opt.updatetime = 250

-- Live preview of :s while it is being typed, in a split showing every line it
-- would touch. The single largest "why did I not have this" option in vim.
opt.inccommand = "split"

-- Relative for the jumps (5k, d3j), absolute on the cursor line so the ruler
-- still says where you are. `number` above is what keeps that one line absolute.
opt.relativenumber = true

-- 300ms and not the 1000ms default: leader is Space, so every chord waits this
-- long before giving up. Short enough not to feel stuck, long enough that
-- `<leader>ca` typed at speed still lands.
opt.timeoutlen = 300

-- Trailing whitespace and hard tabs are invisible until they break a diff.
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

opt.clipboard = "unnamedplus"
opt.confirm = true
opt.swapfile = false
opt.undofile = true

-- Treesitter folding, but never folded on open. foldlevel high enough that a
-- file arrives fully expanded and `zc` is what closes something.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevelstart = 99

-- Diff in vertical splits, ignoring pure indentation churn, with the algorithm
-- git itself defaults to for anything but trivial hunks.
opt.diffopt:append({ "vertical", "algorithm:histogram", "indent-heuristic", "linematch:60" })

-- The ruler is where the FORMATTER will wrap, not a taste. Each number is that
-- tool's own default, so the column marks the line conform is about to enforce
-- on save rather than a rule nothing applies:
--   rustfmt max_width   100   (rustfmt --print-config default)
--   prettier printWidth  80
--   stylua column_width 120
-- go and sh get none: gofmt does not wrap lines at all, and neither does shfmt.
local ruler = {
  rust = 100,
  lua = 120,
  typescript = 80,
  typescriptreact = 80,
  javascript = 80,
  javascriptreact = 80,
  json = 80,
  jsonc = 80,
  yaml = 80,
  css = 80,
  html = 80,
  markdown = 80,
  gitcommit = 72,
}

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dotfiles.options", { clear = true }),
  callback = function(args)
    local width = ruler[vim.bo[args.buf].filetype]
    if not width then
      return
    end
    vim.opt_local.colorcolumn = tostring(width)
    -- textwidth only for markdown, and only textwidth. Its ftplugin already
    -- puts `t` in formatoptions but leaves textwidth at 0, so nothing wraps —
    -- this is the missing half, and it makes typing agree with the column
    -- prettier enforces on save. gitcommit needs neither: its own ftplugin sets
    -- both. Code filetypes get no textwidth at all; breaking a line mid
    -- expression is the formatter's job, not the editor's.
    if vim.bo[args.buf].filetype == "markdown" then
      vim.opt_local.textwidth = width
    end
  end,
})

vim.o.background = "dark"
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")
