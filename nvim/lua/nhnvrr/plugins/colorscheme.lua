return {
  {
    "rebelot/kanagawa.nvim",
    name = "kanagawa",
    lazy = false,
    priority = 1000,
    config = function()
      require("kanagawa").setup({
        theme = "dragon",
        commentStyle = { italic = true },
        statementStyle = { bold = false },
        background = { dark = "dragon", light = "lotus" },
      })
      vim.cmd("colorscheme kanagawa-dragon")
    end,
  },
}
