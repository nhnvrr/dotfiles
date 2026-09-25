vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- netrw is the file tree: `nvim .` or <leader>e. No banner, tree listing.
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3

local augroup = vim.api.nvim_create_augroup("dotfiles", { clear = true })

-- ─── options ────────────────────────────────────────────────────────────────

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
-- Off for code. Prose filetypes turn it on below; these two only matter once
-- something does, and getting them wrong is what makes wrapping unreadable:
-- linebreak breaks at spaces instead of mid-word, breakindent keeps the
-- continuation under the line it belongs to.
opt.wrap = false
opt.linebreak = true
opt.breakindent = true
opt.breakindentopt = "shift:2"
opt.scrolloff = 4
opt.cursorline = true
opt.colorcolumn = "81"
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
  "https://github.com/hrsh7th/nvim-cmp",
  "https://github.com/hrsh7th/cmp-nvim-lsp",
  "https://github.com/hrsh7th/cmp-buffer",
  "https://github.com/hrsh7th/cmp-path",
  "https://github.com/hrsh7th/cmp-cmdline",
  "https://github.com/windwp/nvim-autopairs",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/b0o/SchemaStore.nvim",
  "https://github.com/projekt0n/github-nvim-theme",
})

-- Colours live in lua/mate: one scheme per mode, matching whichever palette
-- alacritty has imported. `mate` flips both ends together.
local mate = require("mate")
mate.apply(mate.mode())
mate.watch()

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

require("nvim-autopairs").setup({ check_ts = true })

local cmp = require("cmp")
cmp.setup({
  -- Required by nvim-cmp even with no snippet plugin; vim.snippet is built in.
  snippet = { expand = function(args) vim.snippet.expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    -- fallback() keeps <C-k> as the native digraph insert when no menu is open.
    ["<C-j>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item() else fallback() end
    end, { "i" }),
    ["<C-k>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item() else fallback() end
    end, { "i" }),
    -- completeopt has noselect, so nothing is highlighted when the menu opens:
    -- the first <Tab> picks an entry, the second one accepts it.
    ["<Tab>"] = cmp.mapping(function(fallback)
      if not cmp.visible() then
        return fallback()
      end
      if cmp.get_selected_entry() then
        cmp.confirm({ behavior = cmp.ConfirmBehavior.Insert })
      else
        cmp.select_next_item()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item() else fallback() end
    end, { "i", "s" }),
    ["<CR>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "path" },
  }, {
    { name = "buffer" },
  }),
  experimental = { ghost_text = true },
})

-- Confirming a function completion appends the pair: `map` -> `map()`.
cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())

-- path first so `:e src/` completes the tree; command names only once no path
-- matches, otherwise every `:` would list the whole command set.
cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
})

-- blink had signature help built in; nvim-cmp does not. doc_lines = 0 keeps it
-- to the signature itself instead of dragging the whole docstring along.
--
-- Deferred to the first LspAttach: with no client there is no signature to show,
-- and requiring it at startup costs ~2.6ms for nothing.
vim.pack.add({ "https://github.com/ray-x/lsp_signature.nvim" })
vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup,
  once = true,
  callback = function()
    require("lsp_signature").setup({ doc_lines = 0, hint_prefix = "» ", handler_opts = { border = "none" } })
  end,
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

require("gitsigns").setup({ current_line_blame_opts = { delay = 500 } })

-- fzf-lua costs ~2.5ms to require and setup, and none of it is needed until a
-- picker is actually opened. Same self-replacing shape as tree() in lua/ui.lua.
local fzf_ready = false
local function fzf(name, opts)
  return function()
    local f = require("fzf-lua")
    if not fzf_ready then
      f.setup({ "hide", fzf_colors = true })
      fzf_ready = true
    end
    f[name](opts)
  end
end

-- ─── keymaps ────────────────────────────────────────────────────────────────

local map = vim.keymap.set

map("i", "jk", "<Esc>")
map("n", "<Esc>", "<Cmd>nohlsearch<CR>")
map("n", "<leader>w", "<Cmd>write<CR>", { desc = "Save" })
map("n", "<leader>q", "<Cmd>quit<CR>", { desc = "Quit" })

map("n", "<leader>ff", fzf("files"), { desc = "Files" })
map("n", "<leader>fg", fzf("live_grep"), { desc = "Grep" })
map("n", "<leader>fb", fzf("buffers"), { desc = "Buffers" })
map("n", "<leader>fr", fzf("oldfiles"), { desc = "Recent" })
map("n", "<leader>fh", fzf("helptags"), { desc = "Help" })
map("n", "<leader>fd", fzf("diagnostics_document"), { desc = "Diagnostics" })
map("n", "<leader>fD", fzf("diagnostics_workspace"), { desc = "Diagnostics (workspace)" })
map("n", "<leader>fs", fzf("lsp_document_symbols"), { desc = "Symbols" })
map("n", "<leader>fS", fzf("lsp_workspace_symbols"), { desc = "Symbols (workspace)" })
map("n", "<leader>fw", fzf("grep_cword"), { desc = "Word under cursor" })
-- The picker you just closed, with its query and cursor position intact.
map("n", "<leader>f.", fzf("resume"), { desc = "Resume last picker" })

map("n", "<leader>gs", "<Cmd>Gitsigns stage_hunk<CR>", { desc = "Stage hunk" })
map("n", "<leader>gr", "<Cmd>Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
map("n", "<leader>gp", "<Cmd>Gitsigns preview_hunk<CR>", { desc = "Preview hunk" })
map("n", "<leader>gb", "<Cmd>Gitsigns toggle_current_line_blame<CR>", { desc = "Blame" })
-- git_status previews the diff and stages from the picker itself: ctrl-s stage,
-- ctrl-u unstage, ctrl-x reset.
map("n", "<leader>gf", fzf("git_status"), { desc = "Changed files" })
map("n", "<leader>gc", fzf("git_commits"), { desc = "Commits" })
map("n", "<leader>gC", fzf("git_bcommits"), { desc = "Commits (this file)" })
map("n", "<leader>gB", fzf("git_branches"), { desc = "Branches" })
map("n", "]h", "<Cmd>Gitsigns nav_hunk next<CR>", { desc = "Next hunk" })
map("n", "[h", "<Cmd>Gitsigns nav_hunk prev<CR>", { desc = "Previous hunk" })

map("n", "<leader>cf", function() require("conform").format({ async = true }) end, { desc = "Format" })

-- <C-w>v and <C-w>s already do this; the leader set is the one-hand version.
map("n", "<leader>sv", "<Cmd>vsplit<CR>", { desc = "Split vertical" })
map("n", "<leader>sh", "<Cmd>split<CR>", { desc = "Split horizontal" })
map("n", "<leader>sx", "<Cmd>close<CR>", { desc = "Close window" })

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

-- Prose soft-wraps at the window edge. Removing `t` from formatoptions is what
-- makes that true: with it, textwidth hard-wraps while you type and the file
-- fills with line breaks. Without it textwidth only drives an explicit `gq`,
-- so a paragraph stays one line and a diff shows the sentence that changed
-- rather than every line after it.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "markdown", "text", "gitcommit", "mail" },
  callback = function(args)
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
    vim.opt_local.formatoptions:remove("t")
    -- 72 is the git convention for a commit body, and nvim's own gitcommit
    -- ftplugin already sets it; 80 elsewhere.
    local width = (args.match == "gitcommit" or args.match == "mail") and 72 or 80
    vim.opt_local.textwidth = width
    vim.opt_local.colorcolumn = tostring(width + 1)
    -- j and k move by screen line once a line spans several of them; a count
    -- still reaches the real line, so 5j means five file lines.
    for _, key in ipairs({ "j", "k" }) do
      map({ "n", "x" }, key, function()
        return vim.v.count == 0 and ("g" .. key) or key
      end, { buffer = args.buf, expr = true })
    end
  end,
})

vim.api.nvim_create_user_command("WrapToggle", function()
  vim.opt_local.wrap = not vim.wo.wrap
end, {})

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

-- fzf has no normal mode, so jk closes the picker the way it leaves insert.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "fzf",
  callback = function(args)
    map("t", "jk", "<Esc>", { buffer = args.buf })
  end,
})

require("ui")
require("lsp")
