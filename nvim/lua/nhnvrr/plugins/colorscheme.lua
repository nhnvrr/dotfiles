return {
  {
    "AlexvZyl/nordic.nvim",
    name = "nordic",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      require("nordic").setup({
        on_palette = function(palette) end,
        after_palette = function(palette) end,
        on_highlight = function(highlights, palette)
          local yellow = (type(palette.yellow) == "table" and palette.yellow.base) or palette.yellow or "#e5c07b"
          local light_gray = palette.gray0 or palette.gray1 or "#9aa3b2"
          local dark_bg = "#191d24"
          highlights.NeoTreeTabActive = { fg = yellow, bg = dark_bg, bold = true }
          highlights.NeoTreeTabInactive = { fg = light_gray, bg = dark_bg }
          highlights.NeoTreeTabSeparatorActive = { fg = yellow, bg = dark_bg }
          highlights.NeoTreeTabSeparatorInactive = { fg = light_gray, bg = dark_bg }
        end,
        bold_keywords = false,
        italic_comments = true,
        transparent = {
          bg = false,
          float = false,
        },
        bright_border = false,
        reduced_blue = false,
        swap_backgrounds = false,
        cursorline = {
          bold = false,
          bold_number = true,
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
