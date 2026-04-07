return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  dependencies = {
    {
      "OXY2DEV/markview.nvim",
      lazy = false,
    },
  },
  config = function()
    local ts = require("nvim-treesitter")
    local ts_lang = vim.treesitter.language

    ts.setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    ts.install({
      "json",
      "javascript",
      "typescript",
      "tsx",
      "yaml",
      "html",
      "css",
      "prisma",
      "markdown",
      "markdown_inline",
      "svelte",
      "graphql",
      "bash",
      "lua",
      "vim",
      "dockerfile",
      "gitignore",
      "query",
      "vimdoc",
      "c",
      "go",
      "gomod",
      "gosum",
      "gowork",
    })

    local function load_lang_for_ft(ft)
      local lang = ts_lang.get_lang(ft)
      if not lang then
        return
      end

      local ok = ts_lang.add(lang)
      if ok then
        return lang
      end
    end

    -- Start Treesitter highlighting on every filetype.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local ft = vim.bo[args.buf].filetype
        local lang = load_lang_for_ft(ft)
        if lang then
          vim.treesitter.start(args.buf, lang)
        end
      end,
    })

    -- Use Treesitter-based indentexpr (experimental in rewrite).
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        local ft = vim.bo.filetype
        local lang = load_lang_for_ft(ft)
        if lang then
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })

    vim.treesitter.language.register("bash", "zsh")
  end,
}
