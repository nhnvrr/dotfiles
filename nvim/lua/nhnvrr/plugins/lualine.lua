return {
  "nvim-lualine/lualine.nvim",
  dependencies = {},
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status")

    lualine.setup({
      options = {
        theme = "auto",
        globalstatus = true,
        component_separators = "",
        section_separators = "",
      },
      sections = {
        lualine_a = {
          {
            "mode",
            padding = { left = 1, right = 1 },
            fmt = function(mode)
              local short = {
                NORMAL = "N",
                INSERT = "I",
                VISUAL = "V",
                ["V-LINE"] = "VL",
                ["V-BLOCK"] = "VB",
                REPLACE = "R",
                ["V-REPLACE"] = "VR",
                COMMAND = "C",
                TERMINAL = "T",
                SELECT = "S",
                ["S-LINE"] = "SL",
                ["S-BLOCK"] = "SB",
              }
              return short[mode] or mode
            end,
          },
        },
        lualine_b = { "branch" },
        lualine_c = {
          {
            "filename",
            path = 1, -- show path relative to cwd for quick reference
            shorting_target = 80,
            symbols = { modified = "[+]", readonly = "[ro]", unnamed = "[No Name]" },
          },
        },
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
          },
          { "diagnostics", sources = { "nvim_diagnostic" } },
          { "filetype",    icon_only = false },
        },
        lualine_y = { "progress" },
        lualine_z = { { "location", padding = { left = 1, right = 1 } } },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
    })
  end,
}
