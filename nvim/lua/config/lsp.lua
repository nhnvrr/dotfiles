-- LSP keymaps on attach
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true }

    -- Neovim 0.12 provides these defaults:
    --   grr  = references
    --   gri  = implementations
    --   grn  = rename
    --   gra  = code actions
    --   grt  = type definition
    --   gO   = document symbols
    --   C-S  = signature help (insert mode)
    --
    -- We only add mappings that use fzf-lua or aren't covered by defaults.

    -- 0.12 defaults: grr, gri, grn, gra, grt, gO, gD, K, C-S
    -- Only override gd to use fzf-lua for better UI:

    opts.desc = "Show LSP definitions (fzf-lua)"
    vim.keymap.set("n", "gd", "<cmd>FzfLua lsp_definitions<CR>", opts)

    opts.desc = "Restart LSP"
    vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
  end,
})

-- Server configurations (native vim.lsp.config, no nvim-lspconfig needed)
vim.lsp.config("*", {
  capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = true,
        },
      },
    },
  },
})

vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      completion = { callSnippet = "Replace" },
    },
  },
})

vim.lsp.config("ts_ls", {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})

vim.lsp.config("html", {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html" },
  root_markers = { ".git" },
})

vim.lsp.config("cssls", {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less" },
  root_markers = { ".git" },
})

vim.lsp.config("tailwindcss", {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = { "html", "css", "javascriptreact", "typescriptreact", "svelte" },
  root_markers = { "tailwind.config.js", "tailwind.config.ts", "tailwind.config.cjs", "tailwind.config.mjs" },
})

vim.lsp.config("eslint", {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = {
    "javascript", "typescript", "html",
    "typescriptreact", "javascriptreact",
    "css", "sass", "scss", "less", "svelte",
  },
  root_markers = { "eslint.config.js", ".eslintrc.cjs", ".eslintrc.js", ".eslintrc.json", ".eslintrc", "package.json" },
  settings = {
    validate = "on",
    packageManager = nil,
    useESLintClass = false,
    experimental = { useFlatConfig = nil },
    codeActionOnSave = { enable = false, mode = "all" },
    format = false,
    quiet = false,
    onIgnoredFiles = "off",
    rulesCustomizations = {},
    run = "onType",
    problems = { shortenToSingleLine = false },
    nodePath = "",
    workingDirectory = { mode = "auto" },
  },
})

vim.lsp.config("graphql", {
  cmd = { "graphql-lsp", "server", "-m", "stream" },
  filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
  root_markers = { ".graphqlrc*", "graphql.config.*", ".git" },
})

vim.lsp.config("emmet_ls", {
  cmd = { "emmet-ls", "--stdio" },
  filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
  root_markers = { ".git" },
})

vim.lsp.config("prismals", {
  cmd = { "prisma-language-server", "--stdio" },
  filetypes = { "prisma" },
  root_markers = { "schema.prisma", ".git" },
})

vim.lsp.config("yamlls", {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yml" },
  root_markers = { ".git" },
  settings = {
    yaml = {
      validate = true,
      hover = true,
      completion = true,
      format = { enable = true },
      schemaStore = { enable = true, url = "https://www.schemastore.org/api/json/catalog.json" },
      schemas = {
        kubernetes = "*.k8s.yaml",
        ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.{yml,yaml}",
        ["https://json.schemastore.org/github-action.json"] = ".github/actions/*.{yml,yaml}",
        ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose*.{yml,yaml}",
      },
    },
  },
})

vim.lsp.config("marksman", {
  cmd = { "marksman", "server" },
  filetypes = { "markdown" },
  root_markers = { ".marksman.toml", ".git" },
})

vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.mod", "go.work", ".git" },
  settings = {
    gopls = {
      analyses = { unusedparams = true },
      staticcheck = true,
      gofumpt = true,
    },
  },
})

vim.lsp.config("svelte", {
  cmd = { "svelteserver", "--stdio" },
  filetypes = { "svelte" },
  root_markers = { "svelte.config.js", "svelte.config.cjs", ".git" },
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.js", "*.ts" },
      callback = function(ctx)
        client:notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
      end,
    })
  end,
})

-- Enable all servers
vim.lsp.enable({
  "lua_ls",
  "ts_ls",
  "html",
  "cssls",
  "tailwindcss",
  "eslint",
  "graphql",
  "emmet_ls",
  "prismals",
  "yamlls",
  "marksman",
  "gopls",
  "svelte",
})
