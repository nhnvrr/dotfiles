vim.g.mapleader = ' '
-- nvim-tree replaces netrw; it must be off before any plugin loads.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local o = vim.opt
o.number = true
o.relativenumber = true
o.signcolumn = 'yes'
o.cursorline = true
o.cursorlineopt = 'number'
o.colorcolumn = '81'
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.ignorecase = true
o.smartcase = true
o.scrolloff = 4
o.splitbelow = true
o.splitright = true
o.swapfile = false
o.undofile = true
o.clipboard = 'unnamed'
o.laststatus = 2
o.showmode = false
-- mate.vim paints ANSI slots only, so colours come from Ghostty's palette.
o.termguicolors = false
o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20'

vim.pack.add({
  'https://github.com/nvim-mini/mini.nvim',
  'https://github.com/ibhagwan/fzf-lua',
  'https://github.com/nvim-tree/nvim-tree.lua',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/stevearc/conform.nvim',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  -- A release tag is what lets blink download its prebuilt fuzzy binary.
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
})

vim.cmd.colorscheme('mate')

-- Icons first: fzf-lua and nvim-tree look them up at setup.
require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()
local sl = require('mini.statusline')
local function counts(items, hide_width)
  if sl.is_truncated(hide_width) then return '' end
  local out = {}
  for _, it in ipairs(items) do
    if (it[1] or 0) > 0 then out[#out + 1] = '%#' .. it[3] .. '#' .. it[2] .. it[1] end
  end
  return table.concat(out, ' ')
end
sl.setup({
  content = {
    active = function()
      local mode, mode_hl = sl.section_mode({ trunc_width = 120 })
      local d = vim.b.gitsigns_status_dict or {}
      local diff = counts({
        { d.added, '+', 'StatusLineAdd' },
        { d.changed, '~', 'StatusLineChange' },
        { d.removed, '-', 'StatusLineDelete' },
      }, 75)
      local s, n = vim.diagnostic.severity, vim.diagnostic.count(0)
      local diag = counts({
        { n[s.ERROR], 'E', 'StatusLineError' },
        { n[s.WARN], 'W', 'StatusLineWarn' },
        { n[s.INFO], 'I', 'StatusLineInfo' },
        { n[s.HINT], 'H', 'StatusLineHint' },
      }, 75)
      -- No hl: each item carries its own %#Group#, and an empty group without
      -- hl would still add padding, so it is dropped instead.
      local coloured = vim.trim(diff .. ' ' .. diag)
      return sl.combine_groups({
        { hl = mode_hl, strings = { mode } },
        { hl = 'MiniStatuslineDevinfo', strings = { sl.section_git({ trunc_width = 40 }) } },
        coloured ~= '' and { strings = { coloured } } or '',
        { hl = 'MiniStatuslineDevinfo', strings = { sl.section_lsp({ trunc_width = 75 }) } },
        '%<',
        { hl = 'MiniStatuslineFilename', strings = { sl.section_filename({ trunc_width = 140 }) } },
        '%=',
        { hl = 'MiniStatuslineFileinfo', strings = { sl.section_fileinfo({ trunc_width = 120 }) } },
        { hl = mode_hl, strings = { sl.section_searchcount({ trunc_width = 75 }), sl.section_location({ trunc_width = 75 }) } },
      })
    end,
  },
})
require('mini.pairs').setup()
require('mini.surround').setup()
require('mini.ai').setup()

local clue = require('mini.clue')
clue.setup({
  triggers = {
    { mode = 'n', keys = '<Leader>' }, { mode = 'x', keys = '<Leader>' },
    { mode = 'n', keys = 'g' }, { mode = 'x', keys = 'g' },
    { mode = 'n', keys = 'z' }, { mode = 'x', keys = 'z' },
    { mode = 'n', keys = '[' }, { mode = 'n', keys = ']' },
    { mode = 'n', keys = '<C-w>' },
    { mode = 'n', keys = '"' }, { mode = 'x', keys = '"' },
    { mode = 'n', keys = "'" }, { mode = 'n', keys = '`' },
    { mode = 'i', keys = '<C-r>' }, { mode = 'c', keys = '<C-r>' },
    { mode = 'i', keys = '<C-x>' },
  },
  clues = {
    clue.gen_clues.builtin_completion(),
    clue.gen_clues.g(),
    clue.gen_clues.marks(),
    clue.gen_clues.registers(),
    clue.gen_clues.windows(),
    clue.gen_clues.z(),
    { mode = 'n', keys = '<Leader>h', desc = '+git hunk' },
  },
})

require('fzf-lua').setup({ defaults = { file_icons = 'mini' } })
require('nvim-tree').setup({
  update_focused_file = { enable = true },
  filters = { dotfiles = false, git_ignored = false },
})
require('render-markdown').setup({})

require('gitsigns').setup({
  on_attach = function(buf)
    local gs = require('gitsigns')
    local function m(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = buf, desc = desc })
    end
    m(']h', function() gs.nav_hunk('next') end, 'Next hunk')
    m('[h', function() gs.nav_hunk('prev') end, 'Previous hunk')
    m('<leader>hs', gs.stage_hunk, 'Stage hunk')
    m('<leader>hr', gs.reset_hunk, 'Reset hunk')
    m('<leader>hp', gs.preview_hunk, 'Preview hunk')
    m('<leader>hb', gs.blame_line, 'Blame line')
  end,
})

require('blink.cmp').setup({
  keymap = { preset = 'default' },
  completion = { documentation = { auto_show = true } },
  signature = { enabled = true },
  fuzzy = { implementation = 'prefer_rust_with_warning' },
})

vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
    },
  },
})
vim.lsp.enable({
  'lua_ls', 'bashls', 'gopls', 'terraformls', 'basedpyright', 'vtsls',
  'eslint', 'jsonls', 'yamlls', 'taplo', 'rust_analyzer',
})
vim.diagnostic.config({ virtual_text = true, severity_sort = true })

require('conform').setup({
  formatters_by_ft = {
    lua = { 'stylua' },
    go = { 'gofmt' },
    python = { 'ruff_format' },
    sh = { 'shfmt' },
    bash = { 'shfmt' },
    terraform = { 'terraform_fmt' },
    javascript = { 'prettierd' },
    javascriptreact = { 'prettierd' },
    typescript = { 'prettierd' },
    typescriptreact = { 'prettierd' },
    json = { 'prettierd' },
    yaml = { 'prettierd' },
    markdown = { 'prettierd' },
  },
  format_on_save = { timeout_ms = 1000, lsp_format = 'fallback' },
})

require('nvim-treesitter').install({
  'bash', 'json', 'toml', 'yaml', 'lua', 'vim', 'vimdoc', 'markdown',
  'markdown_inline', 'go', 'rust', 'python', 'typescript', 'tsx', 'javascript', 'hcl', 'terraform',
})
vim.treesitter.language.register('bash', 'zsh')
vim.api.nvim_create_autocmd('FileType', {
  callback = function() pcall(vim.treesitter.start) end,
})

local map = vim.keymap.set
local fzf = require('fzf-lua')
map('n', '<leader>e', '<cmd>NvimTreeToggle<cr>', { desc = 'File explorer' })
map('n', '<leader>ff', fzf.files, { desc = 'Find files' })
map('n', '<leader>p', fzf.files, { desc = 'Files' })
map('n', '<leader>/', fzf.live_grep, { desc = 'Grep' })
map('n', '<leader>b', fzf.buffers, { desc = 'Buffers' })
map('n', '<leader>s', fzf.lsp_document_symbols, { desc = 'Symbols' })
map('n', '<leader>d', fzf.diagnostics_document, { desc = 'Diagnostics' })
map('n', 'gd', fzf.lsp_definitions, { desc = 'Definitions' })
map('n', '<Esc><Esc>', '<cmd>nohlsearch<cr>')
map('v', 'J', ":m '>+1<cr>gv=gv")
map('v', 'K', ":m '<-2<cr>gv=gv")
map('i', 'jk', '<Esc>')
