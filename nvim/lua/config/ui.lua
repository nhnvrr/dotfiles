require("neo-tree").setup({
  close_if_last_window = true,
  filesystem = {
    hijack_netrw_behavior = "open_current",
    follow_current_file = { enabled = true },
    filtered_items = {
      -- visible, not unfiltered: gitignored files still render as ignored
      -- instead of passing for tracked ones. never_show wins over this.
      visible = true,
      hide_dotfiles = false,
      hide_gitignored = true,
      never_show = { "node_modules" },
    },
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
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics (project)" })
vim.keymap.set("n", "<leader>h", builtin.help_tags, { desc = "Help tags" })

-- Built per family and mode rather than left on lualine's "auto", which would
-- follow the colorscheme by itself: the loop needs a real table to strip the bold
-- out of the mode block, matching the is_bold sweep in eza/theme.yml. The map
-- lives in config.theme, which owns which family is live.
local theme_cfg = require("config.theme")

local function lualine_theme()
  local name = theme_cfg.LUALINE[theme_cfg.family][theme_cfg.mode()]
  local theme = require("lualine.themes." .. name)
  for _, mode in pairs(theme) do
    mode.a.gui = nil
  end
  return theme
end

local lualine_config = {
  options = {
    theme = lualine_theme(),
    globalstatus = true,
    component_separators = "│",
    section_separators = "",
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = {},
    lualine_c = {
      { "filename", path = 1, symbols = { modified = " [+]", readonly = " ", unnamed = "[No Name]" } },
      { "diagnostics", sources = { "nvim_lsp" } },
    },
    lualine_x = {
      -- Only renders while a session is live, so it costs nothing the rest of
      -- the time and is the clearest signal that the debugger is attached.
      { function() return "  " .. require("dap").status() end,
        cond = function() return package.loaded.dap and require("dap").status() ~= "" end },
      "filetype",
    },
    lualine_y = { "location" },
    lualine_z = { "progress" },
  },
  extensions = { "neo-tree", "nvim-dap-ui" },
}

require("lualine").setup(lualine_config)

-- nvim learns the background from the terminal asynchronously, so the theme built
-- above can be the wrong half of the pair. Re-passing the whole table and not just
-- options is load-bearing: setup() merges with lualine's defaults, so options on
-- their own would wipe the sections.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = { "solarized", "gruvbox", "onedark", "onelight" },
  callback = function()
    lualine_config.options.theme = lualine_theme()
    require("lualine").setup(lualine_config)
  end,
})
