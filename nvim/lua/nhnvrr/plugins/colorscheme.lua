return {
  {
    "webhooked/kanso.nvim",
    lazy = false,
    priority = 1000,
    config = function()
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
        overrides = function(_)
          return {}
        end,
        background = {
          dark = "mist",
          light = "pearl",
        },
        foreground = "default",
        minimal = false,
      })
      vim.cmd.colorscheme("kanso-zen")
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
