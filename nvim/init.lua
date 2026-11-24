vim.g.mapleader = ' '
-- neo-tree replaces netrw; it must be off before any plugin loads.
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

-- Must exist before vim.pack.add, or the first install never fetches the binary.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'fff' and (kind == 'install' or kind == 'update') then
      if not ev.data.active then vim.cmd.packadd('fff') end
      require('fff.download').download_or_build_binary()
    end
  end,
})

vim.pack.add({
  'https://github.com/nvim-mini/mini.nvim',
  'https://github.com/nvim-lualine/lualine.nvim',
  'https://github.com/dmtrKovalenko/fff',
  'https://github.com/ibhagwan/fzf-lua',
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range('3') },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/stevearc/conform.nvim',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  -- A release tag is what lets blink download its prebuilt fuzzy binary.
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
})

vim.cmd.colorscheme('mate')

-- Icons first: fzf-lua and neo-tree look them up at setup.
require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()
local dim = vim.o.background == 'dark' and 248 or 8
require('lualine').setup({
  options = {
    theme = 'mate',
    section_separators = '',
    component_separators = '',
    globalstatus = true,
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = {
      'branch',
      {
        'diff',
        source = function()
          local d = vim.b.gitsigns_status_dict
          if d then return { added = d.added, modified = d.changed, removed = d.removed } end
        end,
        diff_color = { added = { fg = 2 }, modified = { fg = 3 }, removed = { fg = 9 } },
      },
      {
        'diagnostics',
        sources = { 'nvim_diagnostic' },
        diagnostics_color = {
          error = { fg = 9 }, warn = { fg = 3 }, info = { fg = 6 }, hint = { fg = dim },
        },
      },
    },
    lualine_c = { { 'filename', path = 1 } },
    lualine_x = { 'lsp_status', { 'filetype', colored = false } },
    lualine_y = { 'progress' },
    lualine_z = { 'searchcount', 'location' },
  },
  extensions = { 'neo-tree' },
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
require('fff').setup({
  -- jk (imap to <Esc>) drops to normal mode, where j/k move the selection.
  prompt_vim_mode = true,
  prompt = '> ',
  keymaps = {
    move_up = { '<Up>', '<C-p>', '<C-k>' },
    move_down = { '<Down>', '<C-n>', '<C-j>' },
  },
})
require('neo-tree').setup({
  close_if_last_window = true,
  popup_border_style = 'rounded',
  source_selector = { winbar = true },
  window = {
    width = 32,
    mappings = {
      ['l'] = 'open',
      ['h'] = 'close_node',
    },
  },
  filesystem = {
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
    hijack_netrw_behavior = 'open_current',
    filtered_items = { hide_dotfiles = false, hide_gitignored = false },
  },
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
map('n', '<leader>e', '<cmd>Neotree toggle<cr>', { desc = 'File explorer' })
local fff = require('fff')
map('n', '<leader>ff', fff.find_files, { desc = 'Find files' })
map('n', '<leader>p', fff.find_files, { desc = 'Files' })
map('n', '<leader>/', fzf.live_grep, { desc = 'Grep' })
map('n', '<leader>b', fzf.buffers, { desc = 'Buffers' })
map('n', '<leader>s', fzf.lsp_document_symbols, { desc = 'Symbols' })
map('n', '<leader>d', fzf.diagnostics_document, { desc = 'Diagnostics' })
map('n', 'gd', fzf.lsp_definitions, { desc = 'Definitions' })
map('n', '<leader>-', '<cmd>split<cr>', { desc = 'Horizontal split' })
map('n', '<leader>|', '<cmd>vsplit<cr>', { desc = 'Vertical split' })
for _, k in ipairs({ 'h', 'j', 'k', 'l' }) do
  map('n', '<C-' .. k .. '>', '<C-w>' .. k, { desc = 'Window ' .. k })
end
map('n', '<Esc><Esc>', '<cmd>nohlsearch<cr>')
map('v', 'J', ":m '>+1<cr>gv=gv")
map('v', 'K', ":m '<-2<cr>gv=gv")
map('i', 'jk', '<Esc>')
