return {
  "lukas-reineke/indent-blankline.nvim",
  event = { "BufReadPre", "BufNewFile" },
  main = "ibl",
  opts = {
    indent = {
      char = "┊",
      tab_char = "┊",
      highlight = "IblIndent",
    },
    whitespace = {
      highlight = { "IblWhitespace" },
    },
    scope = { enabled = false, highlight = "IblScope" },
  },
}
