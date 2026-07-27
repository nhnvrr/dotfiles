-- nvim as $EDITOR/$VISUAL and fish's Ctrl-O, not as an IDE. Day-to-day work is
-- in VS Code, so there's no LSP, completion, treesitter or DAP here.

vim.g.mapleader = " "

-- fzf-native is a C library and vim.pack has no build hook, so the make runs
-- from PackChanged (:h vim.pack-events). This MUST stay above vim.pack.add or
-- it won't fire on a fresh machine, which is the only run that matters.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "telescope-fzf-native.nvim" and ev.data.kind ~= "delete" then
      -- :wait() is not optional. vim.system is async, so without it quitting
      -- before make finishes leaves no libfzf.so and telescope silently falls
      -- back to the Lua sorter.
      local done = vim.system({ "make" }, { cwd = ev.data.path }):wait()
      if done.code ~= 0 then
        vim.notify("fzf-native build failed: " .. (done.stderr or ""), vim.log.levels.ERROR)
      end
    end
  end,
})

vim.pack.add({
  "https://github.com/datsfilipe/vesper.nvim",
  -- neo-tree's dependencies: nui draws the tree, plenary scans the filesystem,
  -- devicons needs the Nerd Font fallback Ghostty already loads.
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  -- v3.x is the branch upstream pins for stability; default branch moves.
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
  -- telescope reuses plenary above; fzf-native is the C sorter.
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
})

-- transparent = true: the terminal supplies the background, so nvim inherits
-- Ghostty's theme without hardcoding a hex here.
require("vesper").setup({ transparent = true })
vim.o.background = "dark"
vim.cmd.colorscheme("vesper")

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

-- neo-tree instead of netrw. hijack_netrw_behavior = "open_current" keeps
-- `nvim .` and `:e some/dir/` opening the tree in the current window, the way
-- netrw did, rather than splitting off a sidebar and leaving an empty buffer.
-- Inside: <CR> opens, `a` new file (trailing `/` makes a directory), `d` delete,
-- `r` rename, `H` toggles hidden files, `?` lists every mapping.
require("neo-tree").setup({
  close_if_last_window = true,
  filesystem = {
    hijack_netrw_behavior = "open_current",
    -- Keep the tree pointed at the buffer being edited.
    follow_current_file = { enabled = true },
    filtered_items = { hide_dotfiles = false, hide_gitignored = true },
  },
  window = { width = 30 },
})
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle reveal left<cr>", { desc = "File explorer" })

require("telescope").setup({ defaults = { layout_strategy = "flex" } })
-- pcall: on a fresh install the make above is still running and the extension
-- doesn't exist yet. It loads on the next start; without this nvim errors out.
pcall(require("telescope").load_extension, "fzf")

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>g", builtin.live_grep, { desc = "Grep in project" })
vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>h", builtin.help_tags, { desc = "Help tags" })

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
