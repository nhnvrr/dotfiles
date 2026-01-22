return {
  {
    "AlexvZyl/nordic.nvim",
    name = "nordic",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      require("nordic").setup({})
      vim.cmd.colorscheme("nordic")
    end,
  },
  {
    "kdheepak/monochrome.nvim",
    name = "monochrome",
    lazy = false,
  },
}
