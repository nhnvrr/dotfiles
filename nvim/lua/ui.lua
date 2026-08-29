vim.pack.add({
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/folke/which-key.nvim",
  "https://github.com/kylechui/nvim-surround",
})

require("lualine").setup({
  options = {
    theme = "everforest",
    section_separators = "",
    component_separators = "|",
    globalstatus = true,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "diagnostics", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
  extensions = { "neo-tree", "nvim-dap-ui", "quickfix" },
})

require("which-key").setup({ preset = "helix", icons = { mappings = false, separator = "->" } })
require("which-key").add({
  { "<leader>c", group = "code" },
  { "<leader>d", group = "debug" },
  { "<leader>f", group = "find" },
  { "<leader>g", group = "git" },
  { "<leader>t", group = "test" },
})

require("nvim-surround").setup({})

local function tree()
  vim.pack.add({
    { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = vim.version.range("3") },
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/MunifTanjim/nui.nvim",
  })
  require("neo-tree").setup({
    close_if_last_window = true,
    window = { width = 32 },
    default_component_configs = {
      git_status = {
        symbols = {
          added = "+", modified = "~", deleted = "-", renamed = ">",
          untracked = "?", conflict = "!", staged = "=", unstaged = "", ignored = "",
        },
      },
    },
    filesystem = {
      filtered_items = { hide_dotfiles = false, hide_gitignored = true },
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
    },
  })
  tree = function() end
end
vim.keymap.set("n", "<leader>e", function()
  tree()
  vim.cmd("Neotree toggle reveal")
end, { desc = "File tree" })

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("dotfiles.tree", { clear = true }),
  callback = function()
    local arg = vim.fn.argv(0)
    if arg ~= "" and vim.fn.isdirectory(arg) == 1 then
      tree()
      vim.cmd("Neotree dir=" .. vim.fn.fnameescape(arg))
    end
  end,
})
