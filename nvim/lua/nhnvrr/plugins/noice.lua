return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    {
      "rcarriga/nvim-notify",
      opts = {
        stages = "fade_in_slide_out",
        timeout = 3500,
        render = "minimal",
        background_colour = "#1b1f27",
        max_height = function()
          return math.floor(vim.o.lines * 0.75)
        end,
        max_width = function()
          return math.floor(vim.o.columns * 0.4)
        end,
      },
      config = function(_, opts)
        require("notify").setup(opts)
        vim.notify = require("notify")
      end,
    },
  },
  keys = {
    { "<leader>nl", "<cmd>Noice last<CR>", desc = "Noice: last message" },
    { "<leader>nH", "<cmd>Noice history<CR>", desc = "Noice: history" },
    { "<leader>ne", "<cmd>Noice errors<CR>", desc = "Noice: errors" },
    { "<leader>nd", "<cmd>Noice dismiss<CR>", desc = "Noice: dismiss" },
  },
  opts = {
    cmdline = {
      enabled = true,
      view = "cmdline_popup",
    },
    messages = {
      enabled = true,
      view = "mini",
      view_error = "notify",
      view_warn = "notify",
      view_history = "messages",
    },
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    presets = {
      bottom_search = true,
      command_palette = true,
      long_message_to_split = true,
      lsp_doc_border = true,
    },
    routes = {
      {
        filter = {
          event = "msg_show",
          kind = "",
          find = "written",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "msg_show",
          find = "yanked",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "msg_show",
          kind = "search_count",
        },
        opts = { skip = true },
      },
    },
    views = {
      cmdline_popup = {
        position = {
          row = "40%",
          col = "50%",
        },
        size = {
          width = 60,
          height = "auto",
        },
        border = {
          style = "rounded",
          padding = { 0, 1 },
        },
      },
      popupmenu = {
        relative = "editor",
        position = {
          row = "46%",
          col = "50%",
        },
        size = {
          width = 60,
          height = 10,
        },
        border = {
          style = "rounded",
          padding = { 0, 1 },
        },
        win_options = {
          winhighlight = { Normal = "Normal", FloatBorder = "FloatBorder" },
        },
      },
    },
  },
}
