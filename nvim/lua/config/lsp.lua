-- '*' is a real server name in vim.lsp.config: it seeds defaults for every
-- other one. Without blink's capabilities here, servers advertise Neovim's
-- stock client and snippets and resolve-support silently degrade.
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities({}, true),
})

vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  float = { source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
})

local ts_inlay_hints = {
  parameterNames = { enabled = "literals" },
  parameterTypes = { enabled = true },
  variableTypes = { enabled = false },
  propertyDeclarationTypes = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  enumMemberValues = { enabled = true },
}

vim.lsp.config("vtsls", {
  cmd = { "vtsls", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  -- Tree-sitter highlights immediately, while vtsls only returns semantic
  -- tokens after loading the whole TypeScript project. Keeping both made an
  -- already-coloured buffer visibly repaint a few seconds after opening it.
  -- This only disables vtsls' colouring layer; types, completion, navigation,
  -- diagnostics and inlay hints remain available.
  on_init = function(client)
    client.server_capabilities.semanticTokensProvider = nil
  end,
  -- Nested list is a priority group: the tsconfig that owns the file wins over
  -- the repo root, which is what keeps a pnpm monorepo from resolving to one
  -- giant project.
  root_markers = { { "tsconfig.json", "jsconfig.json" }, "package.json", ".git" },
  settings = {
    typescript = {
      inlayHints = ts_inlay_hints,
      updateImportsOnFileMove = { enabled = "always" },
      preferences = { importModuleSpecifier = "shortest" },
    },
    javascript = { inlayHints = ts_inlay_hints },
    vtsls = {
      enableMoveToFileCodeAction = true,
      -- Use the repo's own typescript, not the one bundled with vtsls: a
      -- monorepo pinned to an older TS otherwise type-checks against a
      -- different compiler than its build does.
      autoUseWorkspaceTsdk = true,
      experimental = { completion = { enableServerSideFuzzyMatch = true } },
    },
  },
})

-- vscode-eslint-language-server, the same server VS Code runs. It is picky:
-- an incomplete settings table makes it fail on the first didChangeConfiguration
-- rather than degrade, so these keys are not optional decoration.
vim.lsp.config("eslint", {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = {
    "javascript", "javascriptreact", "typescript", "typescriptreact",
  },
  root_markers = {
    "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", "eslint.config.ts",
    ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", ".eslintrc.yaml",
    "package.json", ".git",
  },
  settings = {
    validate = "on",
    useESLintClass = false,
    experimental = { useFlatConfig = false },
    codeActionOnSave = { enable = false, mode = "all" },
    -- prettier owns formatting; eslint only reports and fixes rules. Leaving
    -- both on makes them fight on every save.
    format = false,
    quiet = false,
    onIgnoredFiles = "off",
    options = {},
    rulesCustomizations = {},
    run = "onType",
    problems = { shortenToSingleLine = false },
    nodePath = "",
    workingDirectory = { mode = "auto" },
    codeAction = {
      disableRuleComment = { enable = true, location = "separateLine" },
      showDocumentation = { enable = true },
    },
  },
})

vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { { "go.work", "go.mod" }, ".git" },
  settings = {
    gopls = {
      analyses = { unusedparams = true, shadow = true, nilness = true, unusedwrite = true },
      staticcheck = true,
      gofumpt = true,
      usePlaceholders = true,
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
})

vim.lsp.config("jsonls", {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_markers = { ".git" },
  -- Mutated in place, never reassigned: vim.lsp.Client captures
  -- `settings = config.settings` when it is created, which is before this runs.
  -- The `config.settings = vim.tbl_deep_extend(...)` shown in
  -- :h vim.lsp.ClientConfig binds a new table the client never reads.
  before_init = function(_, config)
    config.settings.json.schemas = require("schemastore").json.schemas()
  end,
  settings = {
    json = {
      validate = { enable = true },
      format = { enable = false },
    },
  },
})

vim.lsp.config("yamlls", {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
  root_markers = { ".git" },
  -- Same in-place mutation as jsonls above, for the same reason.
  before_init = function(_, config)
    config.settings.yaml.schemas = require("schemastore").yaml.schemas()
  end,
  settings = {
    yaml = {
      -- The built-in store is disabled so SchemaStore.nvim is the only source;
      -- with both on, the two fight over the same file and the wrong one wins
      -- roughly half the time.
      schemaStore = { enable = false, url = "" },
      validate = true,
      -- On by default, and it flags every key that is not alphabetically
      -- sorted — which is every serverless.yml ever written.
      keyOrdering = false,
      format = { enable = false },
    },
    redhat = { telemetry = { enabled = false } },
  },
})

-- rust-analyzer is deliberately absent from this list: rustaceanvim starts and
-- owns it. Enabling it here as well puts two clients on the same buffer.
vim.lsp.enable({ "vtsls", "eslint", "gopls", "jsonls", "yamlls" })

-- Read lazily, when the first rust buffer starts a client, so setting it here
-- rather than before vim.pack.add is fine.
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true, buildScripts = { enable = true } },
        procMacro = { enable = true },
        checkOnSave = true,
        check = { command = "clippy" },
        inlayHints = {
          bindingModeHints = { enable = false },
          closureReturnTypeHints = { enable = "with_block" },
          parameterHints = { enable = true },
          typeHints = { enable = true },
        },
      },
    },
  },
}

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
    end

    -- grr, gri, grn, gra, grt, K and gO are already Neovim's own defaults.
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")

    -- Declaration is a C/C++ header idea. tsserver reports declarationProvider
    -- false and gopls has nothing else to point at either, so unconditionally
    -- mapping it would leave gD dead on both servers here.
    map("n", "gD", function()
      for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        if c:supports_method("textDocument/declaration") then
          return vim.lsp.buf.declaration()
        end
      end
      vim.lsp.buf.definition()
    end, "Go to declaration (definition if unsupported)")

    map("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")

    if client and client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
      map("n", "<leader>li", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }),
          { bufnr = args.buf })
      end, "Toggle inlay hints")
    end

    -- What VS Code's "eslint.format.enable + fixAll on save" does. It has to be
    -- the synchronous request: the async code_action path returns before the
    -- edits land and the buffer gets written unfixed.
    if client and client.name == "eslint" then
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = args.buf,
        callback = function()
          client:request_sync("workspace/executeCommand", {
            command = "eslint.applyAllFixes",
            arguments = { {
              uri = vim.uri_from_bufnr(args.buf),
              version = vim.lsp.util.buf_versions[args.buf],
            } },
          }, 1000, args.buf)
        end,
      })
    end
  end,
})
