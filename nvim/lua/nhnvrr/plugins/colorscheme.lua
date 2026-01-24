return {
  {
    "vague2k/vague.nvim",
    name = "vague",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      require("vague").setup({
        bold = false,
        style = {
          comments = "italic",
        },
      })
      vim.cmd.colorscheme("vague")
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
      vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
      vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
    end,
  },
}
