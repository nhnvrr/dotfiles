require("conform").setup({
  formatters_by_ft = {
    javascript = { "prettierd" },
    typescript = { "prettierd" },
    javascriptreact = { "prettierd" },
    typescriptreact = { "prettierd" },
    css = { "prettierd" },
    html = { "prettierd" },
    json = { "prettierd" },
    yaml = { "prettierd" },
    yml = { "prettierd" },
    markdown = { "prettierd" },
    liquid = { "prettierd" },
    terraform = { "terraform_fmt" },
    lua = { "stylua" },
  },
  format_on_save = {
    lsp_format = "fallback",
    async = false,
    timeout_ms = 3000,
  },
})
