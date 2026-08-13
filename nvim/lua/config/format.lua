require("conform").setup({
  formatters_by_ft = {
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    rust = { "rustfmt" },
    -- gopls already formats with gofumpt (see lsp.lua) and is always present
    -- when Go is being edited, so there is no second binary to install.
    go = { lsp_format = "prefer" },
  },

  formatters = {
    -- Without this, prettier runs on repos that never asked for it and rewrites
    -- files the project formats some other way. conform's built-in prettier
    -- definition already resolves cwd from a prettier config; require_cwd turns
    -- "found none" into a skip instead of a run from $HOME.
    prettier = { require_cwd = true },
  },

  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    return { timeout_ms = 1500, lsp_format = "fallback" }
  end,
})

vim.keymap.set({ "n", "v" }, "<leader>lf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })

vim.api.nvim_create_user_command("FormatToggle", function(args)
  if args.bang then
    vim.b.disable_autoformat = not vim.b.disable_autoformat
  else
    vim.g.disable_autoformat = not vim.g.disable_autoformat
  end
end, { bang = true, desc = "Toggle format on save (! for this buffer only)" })

-- Go's missing half: gopls formats but does not add or drop imports, which is
-- a code action rather than a formatting request. This is what `goimports` does
-- in VS Code, without the extra binary.
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function(args)
    if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then
      return
    end
    local params = vim.lsp.util.make_range_params(0, "utf-8")
    params.context = { only = { "source.organizeImports" }, diagnostics = {} }
    local results = vim.lsp.buf_request_sync(args.buf, "textDocument/codeAction", params, 1000)
    for _, res in pairs(results or {}) do
      for _, action in pairs(res.result or {}) do
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
        end
      end
    end
  end,
})
