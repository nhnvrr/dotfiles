vim.g.mapleader = " "

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "telescope-fzf-native.nvim" and ev.data.kind ~= "delete" then
      local done = vim.system({ "make" }, { cwd = ev.data.path }):wait()
      if done.code ~= 0 then
        vim.notify("fzf-native build failed: " .. (done.stderr or ""), vim.log.levels.ERROR)
      end
    end
  end,
})

vim.pack.add({
  "https://github.com/morhetz/gruvbox",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
  "https://github.com/nvim-lualine/lualine.nvim",
})

-- Emptied, not toggled: the theme interpolates this into every group it builds,
-- so it has to be set before the colorscheme loads.
vim.g.gruvbox_bold = 0

-- Vimscript, so there is no setup() and no palette table. The overrides read
-- gruvbox's own Gruvbox* groups instead of hardcoding hex, and run on
-- ColorScheme so they survive a reload. It also has no transparency option:
-- clearing the backgrounds by hand is what keeps Ghostty showing through, float
-- included, so telescope and neo-tree don't draw a lighter rectangle.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "gruvbox",
  callback = function()
    local function fg(group)
      return vim.api.nvim_get_hl(0, { name = group, link = false }).fg
    end
    local bg0, bg2 = fg("GruvboxBg0"), fg("GruvboxBg2")
    local set = vim.api.nvim_set_hl

    for _, group in ipairs({ "Normal", "NormalNC", "NormalFloat", "FloatBorder", "SignColumn", "EndOfBuffer" }) do
      set(0, group, { fg = fg(group), bg = "NONE" })
    end

    -- gruvbox_bold=0 covers everything the theme draws; these three are
    -- Neovim's own defaults, which it never touches. @markup.strong keeps its
    -- bold because there the bold is the meaning.
    for _, group in ipairs({ "PmenuMatch", "PmenuMatchSel", "WinBar" }) do
      local h = vim.api.nvim_get_hl(0, { name = group, link = false })
      h.bold, h.cterm = nil, nil
      set(0, group, h)
    end

    set(0, "NeoTreeDirectoryName", { fg = fg("GruvboxAqua") })
    set(0, "NeoTreeDirectoryIcon", { fg = fg("GruvboxAqua") })
    set(0, "NeoTreeFileName", { fg = fg("GruvboxFg1") })
    set(0, "NeoTreeFileNameOpened", { fg = fg("GruvboxFg1") })

    local title = { fg = bg0, bg = fg("GruvboxOrange") }
    set(0, "TelescopeTitle", title)
    set(0, "TelescopePromptTitle", title)
    set(0, "TelescopeResultsTitle", title)
    set(0, "TelescopePreviewTitle", { fg = bg0, bg = fg("GruvboxBlue") })
    set(0, "TelescopeSelection", { bg = bg2, fg = fg("GruvboxYellow") })
    set(0, "TelescopeSelectionCaret", { bg = bg2, fg = fg("GruvboxYellow") })
  end,
})

vim.o.background = "dark"
vim.cmd.colorscheme("gruvbox")

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

vim.api.nvim_create_user_command("W", "w", {})
vim.api.nvim_create_user_command("Q", "q", {})
vim.api.nvim_create_user_command("Wq", "wq", {})
vim.api.nvim_create_user_command("WQ", "wq", {})

vim.keymap.set("i", "jk", "<Esc>", { desc = "Leave insert mode" })
vim.keymap.set("n", "<leader>nh", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
vim.keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
vim.keymap.set("n", "<leader>sx", "<C-w>q", { desc = "Close split" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left split" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to split below" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to split above" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right split" })

vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Go to left split" })
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Go to split below" })
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Go to split above" })
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Go to right split" })

vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bn", "<cmd>enew<cr>", { desc = "New empty buffer" })
vim.keymap.set("n", "<leader>bd", function()
  local cur = vim.api.nvim_get_current_buf()
  local alt = vim.fn.bufnr("#")
  if alt ~= -1 and vim.fn.buflisted(alt) == 1 then
    vim.cmd("buffer #")
  else
    vim.cmd("bprevious")
  end
  if vim.api.nvim_get_current_buf() == cur then
    vim.cmd("enew")
  end
  vim.cmd("bdelete " .. cur)
end, { desc = "Close buffer (keep window)" })

vim.keymap.set("n", "<leader>tv", "<cmd>vsplit | terminal<cr>", { desc = "Terminal in vertical split" })
vim.keymap.set("n", "<leader>th", "<cmd>split | terminal<cr>", { desc = "Terminal in horizontal split" })

vim.keymap.set({ "n", "v", "i" }, "<ScrollWheelLeft>", "<Nop>")
vim.keymap.set({ "n", "v", "i" }, "<ScrollWheelRight>", "<Nop>")

require("neo-tree").setup({
  close_if_last_window = true,
  filesystem = {
    hijack_netrw_behavior = "open_current",
    follow_current_file = { enabled = true },
    filtered_items = { hide_dotfiles = false, hide_gitignored = true },
  },
  window = { width = 30 },
})
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle reveal left<cr>", { desc = "File explorer" })

require("telescope").setup({
  defaults = {
    layout_strategy = "flex",
    preview = { treesitter = false },
  },
})
pcall(require("telescope").load_extension, "fzf")

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fs", builtin.live_grep, { desc = "Grep in project" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "Git files" })
vim.keymap.set("n", "<leader>fc", builtin.grep_string, { desc = "Grep word under cursor" })
vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>h", builtin.help_tags, { desc = "Help tags" })

local lualine_theme = require("lualine.themes.gruvbox_dark")
for _, mode in pairs(lualine_theme) do
  mode.a.gui = nil
end

require("lualine").setup({
  options = {
    theme = lualine_theme,
    globalstatus = true,
    component_separators = "│",
    section_separators = "",
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch" },
    lualine_c = {
      { "filename", path = 1, symbols = { modified = " [+]", readonly = " ", unnamed = "[No Name]" } },
    },
    lualine_x = { "filetype" },
    lualine_y = { "location" },
    lualine_z = { "progress" },
  },
  extensions = { "neo-tree" },
})

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "help", "man", "qf", "checkhealth" },
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true })
  end,
})
