vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local augroup = vim.api.nvim_create_augroup("dotfiles", { clear = true })

-- ─── options ────────────────────────────────────────────────────────────────

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.wrap = false
opt.scrolloff = 4
opt.cursorline = true
opt.showmode = false
opt.termguicolors = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.ignorecase = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.updatetime = 250
opt.timeoutlen = 300
opt.inccommand = "split"
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.clipboard = "unnamedplus"
opt.confirm = true
opt.swapfile = false
opt.undofile = true
opt.completeopt = { "menu", "menuone", "noselect" }
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevelstart = 99
opt.winborder = "rounded"

-- ─── plugins ────────────────────────────────────────────────────────────────

vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  "https://github.com/neovim/nvim-lspconfig",
  { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1") },
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/b0o/SchemaStore.nvim",
})

vim.o.background = "dark"
vim.cmd.colorscheme("mate")

local parsers = {
  "typescript", "tsx", "javascript", "jsdoc", "go", "gomod", "gosum", "gowork", "rust",
  "json", "yaml", "toml", "lua", "bash", "fish", "markdown", "markdown_inline",
  "html", "css", "sql", "dockerfile", "gitcommit", "diff", "regex", "vim", "vimdoc", "query",
}
require("nvim-treesitter").install(parsers)
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

require("blink.cmp").setup({
  keymap = { preset = "enter" },
  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
    list = { selection = { preselect = false, auto_insert = true } },
  },
  signature = { enabled = true },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
})

require("conform").setup({
  formatters_by_ft = {
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    go = { "gofumpt" },
    rust = { "rustfmt" },
    sh = { "shfmt" },
    lua = { "stylua" },
    toml = { "taplo" },
  },
  format_on_save = function(bufnr)
    if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then
      return
    end
    return { timeout_ms = 2000, lsp_format = "fallback" }
  end,
})
vim.api.nvim_create_user_command("FormatToggle", function(args)
  local scope = args.bang and vim.b or vim.g
  scope.autoformat = scope.autoformat == false
end, { bang = true })

vim.pack.add({ "https://github.com/mfussenegger/nvim-lint" })
require("lint").linters_by_ft = { go = { "golangcilint" } }
vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroup,
  pattern = "*.go",
  callback = function() require("lint").try_lint() end,
})

require("fzf-lua").setup({ "hide", fzf_colors = true })
require("gitsigns").setup({ current_line_blame_opts = { delay = 500 } })

-- ─── keymaps ────────────────────────────────────────────────────────────────

local map = vim.keymap.set
local fzf = require("fzf-lua")

map("i", "jk", "<Esc>")
map("n", "<Esc>", "<Cmd>nohlsearch<CR>")
map("n", "<leader>w", "<Cmd>write<CR>", { desc = "Save" })
map("n", "<leader>q", "<Cmd>quit<CR>", { desc = "Quit" })

map("n", "<leader>ff", fzf.files, { desc = "Files" })
map("n", "<leader>fg", fzf.live_grep, { desc = "Grep" })
map("n", "<leader>fb", fzf.buffers, { desc = "Buffers" })
map("n", "<leader>fr", fzf.oldfiles, { desc = "Recent" })
map("n", "<leader>fh", fzf.helptags, { desc = "Help" })
map("n", "<leader>fd", fzf.diagnostics_document, { desc = "Diagnostics" })
map("n", "<leader>fs", fzf.lsp_document_symbols, { desc = "Symbols" })

map("n", "<leader>gs", "<Cmd>Gitsigns stage_hunk<CR>", { desc = "Stage hunk" })
map("n", "<leader>gr", "<Cmd>Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
map("n", "<leader>gp", "<Cmd>Gitsigns preview_hunk<CR>", { desc = "Preview hunk" })
map("n", "<leader>gb", "<Cmd>Gitsigns toggle_current_line_blame<CR>", { desc = "Blame" })
map("n", "]h", "<Cmd>Gitsigns nav_hunk next<CR>", { desc = "Next hunk" })
map("n", "[h", "<Cmd>Gitsigns nav_hunk prev<CR>", { desc = "Previous hunk" })

map("n", "<leader>cf", function() require("conform").format({ async = true }) end, { desc = "Format" })

for _, dir in ipairs({ "h", "j", "k", "l" }) do
  map("n", "<C-" .. dir .. ">", "<C-w>" .. dir)
end
for _, key in ipairs({ "<C-d>", "<C-u>", "n", "N" }) do
  map("n", key, key .. "zz")
end

map("x", "J", ":m '>+1<CR>gv=gv")
map("x", "K", ":m '<-2<CR>gv=gv")
map("x", "<", "<gv")
map("x", ">", ">gv")
map("x", "p", '"_dP')

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "help", "qf", "man", "checkhealth" },
  callback = function(args)
    map("n", "q", "<Cmd>close<CR>", { buffer = args.buf, silent = true })
  end,
})

require("ui")
require("lsp")

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "go", "rust", "typescript", "typescriptreact", "javascript", "javascriptreact" },
  once = true,
  callback = function()
    vim.schedule(function()
      require("debugger")
      require("testing")
    end)
  end,
})
