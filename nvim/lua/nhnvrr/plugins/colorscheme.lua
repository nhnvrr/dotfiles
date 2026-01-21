return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
        no_bold = true,
        integrations = {
          lualine = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")
      vim.api.nvim_set_hl(0, "Comment", { fg = "#6c7086", italic = true })
      vim.api.nvim_set_hl(0, "@comment", { fg = "#6c7086", italic = true })
    end,
  },
}
