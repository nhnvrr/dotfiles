-- nvim as $EDITOR/$VISUAL and fish's Ctrl-O, not as an IDE. Day-to-day work is
-- in VS Code, so there's no LSP, completion, treesitter or DAP here.

vim.g.mapleader = " "

-- transparent = true: the terminal supplies the background, so nvim inherits
-- #090E13 without hardcoding it.
vim.pack.add({ "https://github.com/webhooked/kanso.nvim" })
require("kanso").setup({ transparent = true, theme = "zen" })
vim.o.background = "dark"
vim.cmd.colorscheme("kanso-zen")

local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

opt.ignorecase = true
opt.smartcase = true

-- Block in normal/visual/command, blinking beam in insert: it's the mode
-- indicator.
opt.guicursor = "n-v-c:block,i-ci-ve:ver25-blinkwait700-blinkon400-blinkoff250,r-cr-o:hor20"

opt.termguicolors = true
opt.cursorline = true
opt.colorcolumn = "100"
opt.scrolloff = 8
opt.wrap = false

opt.clipboard = "unnamedplus"

opt.splitright = true
opt.splitbelow = true

-- No swap, but persistent undo across sessions.
opt.swapfile = false
opt.undofile = true

opt.list = true
opt.listchars = { tab = "▸ ", trail = "·", nbsp = "␣" }

-- Typos from holding Shift too long when saving.
vim.api.nvim_create_user_command("W", "w", {})
vim.api.nvim_create_user_command("Q", "q", {})
vim.api.nvim_create_user_command("Wq", "wq", {})
vim.api.nvim_create_user_command("WQ", "wq", {})

vim.keymap.set("i", "jk", "<Esc>", { desc = "Leave insert mode" })
vim.keymap.set("n", "<leader>nh", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- netrw, which ships with nvim: neo-tree would need four plugins.
-- `:Lexplore` toggles. Inside: <CR> opens, `-` goes up, `%` new file,
-- `d` new directory, `D` delete, `R` rename, `i` cycles views.
vim.g.netrw_liststyle = 3
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
vim.keymap.set("n", "<leader>e", "<cmd>Lexplore<cr>", { desc = "File explorer" })

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

-- Reopening a file puts the cursor back where it was.
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- `q` closes read-only buffers.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "help", "man", "qf", "checkhealth" },
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true })
  end,
})
