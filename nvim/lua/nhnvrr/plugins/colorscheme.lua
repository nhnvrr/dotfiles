return {
  {
    "shaunsingh/nord.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      vim.g.nord_italic = false
      vim.g.nord_bold = false
      vim.g.nord_disable_background = true
      vim.g.nord_disable_float_background = true
      vim.cmd.colorscheme("nord")
      vim.api.nvim_set_hl(0, "Comment", { fg = "#4C566A", italic = true })
      vim.api.nvim_set_hl(0, "@comment", { fg = "#4C566A", italic = true })
    end,
  },
}
