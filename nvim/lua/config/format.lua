local augroup = vim.api.nvim_create_augroup("dotfiles.format", { clear = true })

-- conform replaces the hand-rolled formatter this config used to carry, and
-- with it four separate problems:
--
--   * the old one raised error() inside BufWritePre, which does NOT abort the
--     write — it printed a Lua traceback and saved the file unformatted.
--   * vim.system():wait(5000) re-waits the full timeout after SIGKILL, so a
--     hung formatter froze the editor for up to ten seconds, uninterruptible
--     because vim.wait was called with fast_only.
--   * it preserved 'endofline', which 'fixendofline' overrides anyway.
--   * winsaveview/winrestview ran against the throwaway autocmd window during
--     :wa, so the scroll position was restored into a window being discarded.
vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

local prettier = { "prettier" }

require("conform").setup({
  formatters_by_ft = {
    typescript = prettier,
    typescriptreact = prettier,
    javascript = prettier,
    javascriptreact = prettier,
    json = prettier,
    jsonc = prettier,
    yaml = prettier,
    markdown = prettier,
    css = prettier,
    html = prettier,
    go = { "gofumpt" },
    rust = { "rustfmt" },
    sh = { "shfmt" },
    lua = { "stylua" },
    toml = { "taplo" },
  },

  default_format_opts = {
    -- Only the first formatter that is actually installed runs. Without it a
    -- list is a pipeline, and a missing binary anywhere in it fails the whole
    -- chain.
    stop_after_first = true,
    -- Falls back to the language server's own formatting where no CLI tool is
    -- configured, rather than doing nothing.
    lsp_format = "fallback",
  },

  format_on_save = function(bufnr)
    -- Touching someone else's repo whose style is not yours turns every save
    -- into a whole-file diff. :FormatDisable is the escape hatch.
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    -- 2000ms, not the old 5000: this is synchronous by definition on save, and
    -- a cold prettier on a large monorepo already costs several hundred ms.
    return { timeout_ms = 2000, lsp_format = "fallback" }
  end,
})

-- rustfmt needs the edition, and it does not read Cargo.toml itself when fed on
-- stdin. conform ships a rustfmt formatter that resolves the edition from the
-- nearest manifest; this only pins the fallback for a file outside any crate.
require("conform").formatters.rustfmt = { options = { default_edition = "2024" } }

-- Markdown gets hard-wrapped at 80. prettier's proseWrap defaults to "preserve",
-- which reflows nothing at all — a paragraph written as one long line stays one
-- long line. "always" is what actually re-flows it, and it pairs with the
-- textwidth set in options.lua so typing and saving agree on the same column.
--
-- These are CLI flags, and prettier ranks those above a project .prettierrc, so
-- this wins over a repo that deliberately chose otherwise. That is the point
-- here, but it is worth knowing before wondering why a diff got large.
require("conform").formatters.prettier = {
  prepend_args = function(_, ctx)
    if vim.bo[ctx.buf].filetype == "markdown" then
      return { "--prose-wrap", "always", "--print-width", "80" }
    end
    return {}
  end,
}

vim.api.nvim_create_user_command("Format", function(args)
  local range
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = { start = { args.line1, 0 }, ["end"] = { args.line2, end_line:len() } }
  end
  require("conform").format({ async = true, lsp_format = "fallback", range = range })
end, { range = true, desc = "Format buffer or range" })

vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, { bang = true, desc = "Disable format on save (! for this buffer only)" })

vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, { desc = "Re-enable format on save" })

-- nvim-lint carries exactly one linter. The other two candidates do not belong
-- here: eslint runs as a language server, and shellcheck is executed by
-- bash-language-server itself as soon as the binary is on PATH — no plugin
-- involved, which is why Brewfile declares it with that comment.
vim.pack.add({ "https://github.com/mfussenegger/nvim-lint" })

local lint = require("lint")

lint.linters_by_ft = {
  go = { "golangcilint" },
}

-- BufWritePost only. golangci-lint compiles the package, which takes seconds:
-- TextChanged would fire mid-keystroke and BufReadPost would pay that cost just
-- for opening a file to read it.
vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroup,
  callback = function()
    if lint.linters_by_ft[vim.bo.filetype] then
      lint.try_lint()
    end
  end,
})

vim.keymap.set("n", "<leader>cl", function()
  lint.try_lint()
end, { desc = "Run linters now" })

-- "x" and not "v": "v" also covers Select mode, where <leader> is Space and
-- would start a chord instead of replacing a snippet placeholder.
vim.keymap.set({ "n", "x" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer or selection" })
