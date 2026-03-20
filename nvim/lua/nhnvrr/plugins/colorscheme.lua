local function system_background()
  if vim.fn.has("macunix") ~= 1 then
    return "dark"
  end

  if vim.system then
    local result = vim.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true }):wait()
    if result.code == 0 and result.stdout and result.stdout:match("Dark") then
      return "dark"
    end

    return "light"
  end

  local output = vim.fn.system({ "defaults", "read", "-g", "AppleInterfaceStyle" })
  if vim.v.shell_error == 0 and output:match("Dark") then
    return "dark"
  end

  return "light"
end

return {
  {
    "webhooked/kanso.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local background = system_background()
      local colorscheme = background == "dark" and "kanso-mist" or "kanso-pearl"

      vim.o.background = background

      require("kanso").setup({
        bold = false,
        italics = true,
        compile = false,
        undercurl = true,
        commentStyle = { italic = true },
        functionStyle = {},
        keywordStyle = { italic = true },
        statementStyle = {},
        typeStyle = {},
        transparent = true,
        dimInactive = false,
        terminalColors = true,
        colors = {
          palette = {},
          theme = { zen = {}, pearl = {}, ink = {}, all = {} },
        },
        overrides = function(colors)
          return {
            MarkviewCode = { fg = colors.theme.ui.fg, bg = colors.theme.ui.bg },
            MarkviewCodeFg = { fg = colors.theme.ui.nontext, bg = colors.theme.ui.bg },
            MarkviewCodeInfo = { fg = colors.theme.syn.type, bg = colors.theme.ui.bg, italic = true },
            MarkviewInlineCode = { fg = colors.theme.syn.string, bg = colors.theme.ui.bg },
          }
        end,
        background = {
          dark = "mist",
          light = "pearl",
        },
        foreground = "default",
        minimal = false,
      })
      vim.cmd.colorscheme(colorscheme)
    end,
  },
  -- {
  --   "nhnvrr/nordaurora.nvim",
  --   lazy = false,
  --   priority = 900,
  --   opts = {
  --     transparent = false,
  --     dim_inactive = false,
  --     colors = {
  --       blue = "#81A1C1",
  --     },
  --     on_highlights = function(hl, c)
  --       hl.CursorLineNr = { fg = c.yellow, bold = false }
  --       hl.Comment = { fg = "#6c7a92", italic = true }
  --     end,
  --   },
  --   config = function(_, opts)
  --     require("nordaurora").setup(opts)
  --   end,
  -- },
}
