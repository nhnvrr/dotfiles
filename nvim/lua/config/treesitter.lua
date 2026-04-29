-- nvim-treesitter is only used for parser installation.
-- Highlighting and language detection use built-in vim.treesitter APIs.

local ts_install_ok, ts = pcall(require, "nvim-treesitter")
if ts_install_ok then
  ts.setup({ install_dir = vim.fn.stdpath("data") .. "/site" })
  ts.install({
    "json", "javascript", "typescript", "tsx",
    "yaml", "html", "css", "prisma",
    "markdown", "markdown_inline",
    "bash", "lua", "vim",
    "dockerfile", "gitignore", "query", "vimdoc",
    "c", "go", "gomod", "gosum", "gowork",
  })
end

-- Enable treesitter highlighting for all filetypes with a parser
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
    if not lang then
      return
    end
    -- get_parser returns nil in 0.12 if no parser available
    local parser = vim.treesitter.get_parser(args.buf, lang)
    if parser then
      vim.treesitter.start(args.buf, lang)
    end
  end,
})

-- Register bash as zsh
vim.treesitter.language.register("bash", "zsh")
