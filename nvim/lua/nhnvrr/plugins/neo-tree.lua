return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",
  keys = {
    { "<leader>e",  "<cmd>Neotree toggle<CR>",     desc = "Toggle Neo-tree" },
    { "<leader>EF", "<cmd>Neotree filesystem<CR>", desc = "Neo-tree: Filesystem" },
    { "<leader>EB", "<cmd>Neotree buffers<CR>",    desc = "Neo-tree: Buffers" },
    { "<leader>EG", "<cmd>Neotree git_status<CR>", desc = "Neo-tree: Git status" },
  },
  opts = {
    close_if_last_window = true,
    enable_git_status = true,
    enable_diagnostics = true,
    filesystem = {
      follow_current_file = { enabled = true },
      hijack_netrw_behavior = "open_current",
      use_libuv_file_watcher = true,
      group_empty_dirs = true,
      bind_to_cwd = true,
      window = {
        mappings = {
          ["<space>"] = "none",
          ["l"] = "open",
          ["h"] = "close_node",
          ["v"] = "open_vsplit",
          ["s"] = "open_split",
          ["t"] = "open_tabnew",
          ["R"] = "refresh",
          ["H"] = "toggle_hidden",
          ["Y"] = "copy_to_clipboard",
          ["P"] = "paste_from_clipboard",
        },
      },
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    window = {
      position = "left",
      width = 34,
      mappings = {
        ["<esc>"] = "close_window",
        ["?"] = "show_help",
      },
    },
  },
}
