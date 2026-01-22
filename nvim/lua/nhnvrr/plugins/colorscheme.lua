return {
  {
    "AlexvZyl/nordic.nvim",
    name = "nordic",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      require("nordic").setup({
        on_highlight = function(highlights, palette)
          local yellow = (type(palette.yellow) == "table" and palette.yellow.base) or palette.yellow or "#e5c07b"
          local light_gray = palette.gray0 or palette.gray1 or "#b7becb"
          local dark_bg = "NONE"
          local neo_bg = "NONE"
          local selection_bg = "#3B4252"
          highlights.NeoTreeTabActive = { fg = yellow, bg = dark_bg, bold = true }
          highlights.NeoTreeTabInactive = { fg = light_gray, bg = dark_bg }
          highlights.NeoTreeTabSeparatorActive = { fg = yellow, bg = dark_bg }
          highlights.NeoTreeTabSeparatorInactive = { fg = light_gray, bg = dark_bg }
          highlights.Normal = { bg = dark_bg }
          highlights.NormalFloat = { bg = dark_bg }
          highlights.NeoTreeNormal = { bg = neo_bg }
          highlights.NeoTreeNormalNC = { bg = neo_bg }
          highlights.NeoTreeWinSeparator = { fg = "NONE", bg = neo_bg }
          highlights.Visual = { bg = selection_bg, fg = "NONE" }
          highlights.VisualNOS = { bg = selection_bg, fg = "NONE" }
          highlights.CursorLineNr = { fg = "#97B67C", bold = false }
        end,
        bold_keywords = false,
        italic_comments = true,
        transparent = {
          bg = true,
          float = false,
        },
        bright_border = false,
        reduced_blue = false,
        swap_backgrounds = false,
        cursorline = {
          bold = false,
          bold_number = false,
          theme = "dark",
          blend = 0.85,
        },
        noice = {
          style = "classic",
        },
        telescope = {
          style = "flat",
        },
        leap = {
          dim_backdrop = false,
        },
        ts_context = {
          dark_background = true,
        },
      })
      vim.cmd.colorscheme("nordic")
    end,
  },
  {
    "kdheepak/monochrome.nvim",
    name = "monochrome",
    lazy = false,
  },
}
