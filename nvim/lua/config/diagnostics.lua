local sev = vim.diagnostic.severity

vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  float = {
    border = "rounded",
    source = true,
  },
  signs = {
    text = {
      [sev.ERROR] = "E",
      [sev.WARN] = "W",
      [sev.INFO] = "I",
      [sev.HINT] = "H",
    },
  },
})

-- Diagnostic keymaps
vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump({ count = -1 })
end, { desc = "Go to previous diagnostic" })

vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump({ count = 1 })
end, { desc = "Go to next diagnostic" })

vim.keymap.set("n", "gl", function()
  vim.diagnostic.open_float({
    focusable = false,
    border = "rounded",
    source = true,
    severity_sort = true,
  })
end, { desc = "Show line diagnostic" })

vim.keymap.set("n", "<leader>D", "<cmd>FzfLua diagnostics_document<CR>", { desc = "Buffer diagnostics" })
