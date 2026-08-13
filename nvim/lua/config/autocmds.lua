vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "help", "man", "qf", "checkhealth", "dap-float" },
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true })
  end,
})

-- Serverless config files are YAML but rarely named so, and yamlls only attaches
-- on the yaml filetype.
vim.filetype.add({
  filename = {
    ["serverless.yml"] = "yaml",
    ["serverless.yaml"] = "yaml",
  },
  pattern = {
    [".*/%.github/workflows/.*%.ya?ml"] = "yaml",
  },
})
