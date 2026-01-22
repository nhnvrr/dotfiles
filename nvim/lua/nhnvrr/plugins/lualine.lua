return {
  "nvim-lualine/lualine.nvim",
  dependencies = {},
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status")

    local function hl(name)
      local ok, value = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
      if not ok or not value then
        return {}
      end
      local function hex(n)
        return n and string.format("#%06x", n) or nil
      end
      return { fg = hex(value.fg), bg = hex(value.bg) }
    end

    local normal = hl("StatusLine")
    local inactive = hl("StatusLineNC")
    local accent = hl("Directory")
    local insert = hl("String")
    local visual = hl("Statement")
    local replace = hl("Error")
    local command = hl("Type")
    local green = insert.fg or "#a3be8c"
    local white = normal.fg or "#d8dee9"

    local theme = {
      normal = {
        a = { fg = normal.bg or "#2e3440", bg = accent.fg or "#88c0d0", gui = "bold" },
        b = { fg = normal.fg or "#d8dee9", bg = normal.bg or "#3b4252" },
        c = { fg = normal.fg or "#d8dee9", bg = "none" },
      },
      insert = {
        a = { fg = normal.bg or "#2e3440", bg = insert.fg or "#a3be8c", gui = "bold" },
      },
      visual = {
        a = { fg = normal.bg or "#2e3440", bg = visual.fg or "#b48ead", gui = "bold" },
      },
      replace = {
        a = { fg = normal.bg or "#2e3440", bg = replace.fg or "#bf616a", gui = "bold" },
      },
      command = {
        a = { fg = normal.bg or "#2e3440", bg = command.fg or "#81a1c1", gui = "bold" },
      },
      inactive = {
        a = { fg = inactive.fg or "#4c566a", bg = inactive.bg or "#2e3440", gui = "bold" },
        b = { fg = inactive.fg or "#4c566a", bg = inactive.bg or "#2e3440" },
        c = { fg = inactive.fg or "#4c566a", bg = "none" },
      },
    }

    lualine.setup({
      options = {
        theme = theme,
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { { "mode", padding = { left = 1, right = 1 } } },
        lualine_b = {
          { "branch", icon = "", color = { fg = green, bg = normal.bg or "#3b4252" } },
          {
            "diff",
            symbols = { added = " ", modified = " ", removed = " " },
          },
        },
        lualine_c = {
          {
            "filename",
            path = 1, -- show path relative to cwd for quick reference
            shorting_target = 80,
            symbols = { modified = "●", readonly = "", unnamed = "[No Name]" },
            color = { fg = white, bg = "none" },
          },
        },
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
          },
          { "diagnostics", sources = { "nvim_diagnostic" } },
          { "encoding", padding = { left = 1, right = 1 } },
          { "filetype", icon_only = false },
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
