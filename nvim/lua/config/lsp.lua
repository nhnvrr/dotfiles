local augroup = vim.api.nvim_create_augroup("dotfiles.lsp", { clear = true })

-- One call, not two. vim.diagnostic.config assigns by top-level key
-- (`t[k] = v`, diagnostic.lua), so a second call does not merge into the first
-- — it replaces whole keys. Two calls is how `virtual_text`'s severity filter
-- silently disappears and every hint starts printing inline.
vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  -- Errors only. Every warning and hint printing its full message inline wraps
  -- the window on a TypeScript buffer; the rest are still reachable with
  -- <leader>ds and the sign column says they are there.
  virtual_text = { severity = vim.diagnostic.severity.ERROR, prefix = "●", spacing = 2, source = "if_many" },
  float = { border = "rounded", source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
})

-- vim.fs.root treats a flat list as PRIORITY, not as proximity: it walks every
-- ancestor looking for the first marker before it ever considers the second. A
-- nested table is what means "these rank equally, take the nearest". Getting
-- this wrong in a monorepo puts the root at the repo top instead of the package.
local function root(markers)
  return function(bufnr, on_dir)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path ~= "" then
      on_dir(vim.fs.root(path, markers) or vim.fs.dirname(path))
    end
  end
end

vim.pack.add({ "https://github.com/b0o/SchemaStore.nvim" })

local ts_inlay_hints = {
  parameterNames = { enabled = "literals" },
  parameterTypes = { enabled = true },
  variableTypes = { enabled = true },
  propertyDeclarationTypes = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  enumMemberValues = { enabled = true },
}

vim.lsp.config("vtsls", {
  cmd = { "vtsls", "--stdio" },
  -- javascript is here on purpose: without it a .js buffer got the per-filetype
  -- keymaps registered but no client to send them to, so they did nothing and
  -- said nothing.
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  -- Nested first group: in a monorepo the package's own package.json must win
  -- over a tsconfig.json sitting at the repo root.
  root_dir = root({ { "tsconfig.json", "jsconfig.json", "package.json" }, ".git" }),
  on_init = function(client)
    client.server_capabilities.semanticTokensProvider = nil
  end,
  settings = {
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      preferences = { importModuleSpecifier = "shortest" },
      inlayHints = ts_inlay_hints,
    },
    javascript = { inlayHints = ts_inlay_hints },
    vtsls = {
      autoUseWorkspaceTsdk = true,
      experimental = { completion = { enableServerSideFuzzyMatch = true } },
    },
  },
})

vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork" },
  root_dir = root({ "go.work", "go.mod", ".git" }),
  settings = {
    gopls = {
      gofumpt = true,
      usePlaceholders = true,
      -- staticcheck is the half of Go linting gopls does not run by default,
      -- and these four analysers are the ones that catch real bugs rather than
      -- style: a parameter nobody reads, a nil deref, a shadowed err, a write
      -- that is never observed.
      staticcheck = true,
      analyses = {
        unusedparams = true,
        nilness = true,
        shadow = true,
        unusedwrite = true,
        useany = true,
      },
      codelenses = { gc_details = true, test = true, tidy = true, upgrade_dependency = true },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
})

vim.lsp.config("bashls", {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh" },
  root_dir = root({ ".git" }),
})

vim.lsp.config("yamlls", {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml" },
  root_dir = root({ ".git" }),
  settings = {
    yaml = {
      keyOrdering = false,
      validate = true,
      -- The server ships a handful of schemas; SchemaStore is the catalogue
      -- that knows GitHub Actions, docker-compose and the rest. schemas must be
      -- empty for the store to be consulted at all.
      schemaStore = { enable = false, url = "" },
      schemas = require("schemastore").yaml.schemas(),
    },
    redhat = { telemetry = { enabled = false } },
  },
})

vim.lsp.config("jsonls", {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_dir = root({ "package.json", ".git" }),
  settings = {
    json = {
      validate = { enable = true },
      schemas = require("schemastore").json.schemas(),
    },
  },
})

-- This config is ~1200 lines of Lua editing itself. Without a server, a typo in
-- an API name is found by restarting nvim and reading a traceback.
vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_dir = root({ { ".luarc.json", ".luarc.jsonc", "stylua.toml", ".stylua.toml" }, ".git" }),
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        -- $VIMRUNTIME is what makes the whole vim.* API known. checkThirdParty
        -- off because otherwise every project prompts about luassert and friends.
        library = { vim.env.VIMRUNTIME .. "/lua", "${3rd}/luv/library" },
        checkThirdParty = false,
      },
      diagnostics = { globals = { "vim" } },
      telemetry = { enable = false },
      hint = { enable = true },
    },
  },
})

-- Three TOML files in this repo drive alacritty, mise and herdr. A
-- misspelled key in any of them is currently found by the program behaving oddly.
vim.lsp.config("taplo", {
  cmd = { "taplo", "lsp", "stdio" },
  filetypes = { "toml" },
  root_dir = root({ ".taplo.toml", "taplo.toml", ".git" }),
})

-- eslint. The binary already ships with vscode-langservers-extracted, the same
-- package that provides the json server above.
--
-- Three things here are load-bearing and all three fail silently if omitted.
vim.lsp.config("eslint", {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  root_dir = root({
    { "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", "eslint.config.ts", ".eslintrc.js", ".eslintrc.json", ".eslintrc.cjs" },
    "package.json",
    ".git",
  }),
  -- (1) The server does not derive workspaceFolder from rootUri. Without it it
  -- validates nothing at all and reports no error.
  before_init = function(_, config)
    local dir = config.root_dir or vim.fn.getcwd()
    config.settings = config.settings or {}
    config.settings.workspaceFolder = { uri = vim.uri_from_fname(dir), name = vim.fs.basename(dir) }
  end,
  handlers = {
    -- (2) The VS Code confirmation prompt, over the wire. 4 is "approved". Left
    -- unanswered, the request never resolves and linting never starts.
    ["eslint/confirmESLintExecution"] = function(_, result)
      if not result then
        return
      end
      return 4
    end,
    -- (3) Without these two, every repo that has no eslint raises an LSP
    -- exception on screen instead of a one-line notice.
    ["eslint/noLibrary"] = function()
      vim.notify("eslint: no ESLint library found for this project", vim.log.levels.WARN)
      return {}
    end,
    ["eslint/probeFailed"] = function()
      vim.notify("eslint: probe failed", vim.log.levels.WARN)
      return {}
    end,
    ["eslint/openDoc"] = function(_, result)
      if result and result.url then
        vim.ui.open(result.url)
      end
      return {}
    end,
  },
  settings = {
    validate = "on",
    run = "onType",
    problems = { shortenToSingleLine = false },
    -- prettier owns formatting, from format.lua. Two authorities over the same
    -- buffer fight each other on every write.
    format = false,
    codeActionOnSave = { enable = false, mode = "all" },
    workingDirectory = { mode = "location" },
    useFlatConfig = nil,
    experimental = { useFlatConfig = false },
    nodePath = "",
    onIgnoredFiles = "off",
    quiet = false,
    rulesCustomizations = {},
    options = {},
  },
})

-- typescript-go, the native rewrite of tsserver (npm @typescript/native-preview,
-- binary `tsgo`). Opt-in with `vim.g.typescript_server = "tsgo"` — set it in a
-- .nvim.lua or before this module loads.
--
-- It is genuinely faster: on the same file, 45ms to initialise against vtsls'
-- 80ms, and 23ms to the first hover against 239ms. What it does not have yet,
-- measured rather than assumed:
--   * no workspace/executeCommand at all (vtsls exposes 25)
--   * no source.addMissingImports and no source.fixAll code action
--   * no refactor.* kinds — no extract function, extract variable, move to file
-- organizeImports and removeUnusedImports it does have, which is why the maps
-- below go through code actions instead of vtsls' commands.
vim.lsp.config("tsgo", {
  cmd = { "tsgo", "--lsp", "--stdio" },
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  root_dir = root({ { "tsconfig.json", "jsconfig.json", "package.json" }, ".git" }),
})

-- Env var as well as vim.g: init.lua has already run by the time a `-c` command
-- or a manual :lua could set the global, so `NVIM_TS_SERVER=tsgo nvim` is the
-- only way to switch for a single session without editing a file.
local typescript_server = (vim.env.NVIM_TS_SERVER or vim.g.typescript_server) == "tsgo" and "tsgo" or "vtsls"

-- rust_analyzer is deliberately absent from this list: rustaceanvim owns that
-- client and enabling it here too starts a second server on the same project.
vim.lsp.enable({
  typescript_server,
  "gopls",
  "bashls",
  "yamlls",
  "jsonls",
  "lua_ls",
  "taplo",
  "eslint",
})

-- rustaceanvim is not an lspconfig entry, it is a client of its own. It exposes
-- what rust-analyzer offers but a generic client never asks for: runnables and
-- debuggables under the cursor, macro expansion in its own window, grouped code
-- actions, parent module, and the Cargo integration the test runner uses.
--
-- vim.g.rustaceanvim must be set BEFORE the plugin loads; read at load time, a
-- later assignment is ignored.
--
-- lldb-dap comes with Xcode, so Rust debugging needs nothing installed. It is
-- resolved through xcrun rather than hardcoded because the path differs between
-- Xcode and the Command Line Tools. The tradeoff is that Xcode's lldb-dap has
-- no Rust pretty-printers: a Vec<T> or a String shows as its raw representation.
local lldb_dap = vim.fn.exepath("lldb-dap")
if lldb_dap == "" then
  local probe = vim.system({ "xcrun", "-f", "lldb-dap" }, { text = true }):wait()
  if probe.code == 0 then
    lldb_dap = vim.trim(probe.stdout)
  end
end

vim.g.rustaceanvim = {
  tools = {
    float_win_config = { border = "rounded" },
  },
  server = {
    -- rustaceanvim does not go through the '*' entry that completion.lua sets,
    -- so blink's capabilities have to be handed to it explicitly or Rust loses
    -- snippet and auto-import support that every other language has.
    capabilities = require("blink.cmp").get_lsp_capabilities(nil, true),
    default_settings = {
      ["rust-analyzer"] = {
        -- The single most valuable setting in the file. Off, nothing runs on
        -- save and clippy's findings only exist if you open a terminal; set to
        -- clippy, every lint lands in the same diagnostic list as everything else.
        checkOnSave = true,
        check = { command = "clippy", extraArgs = { "--no-deps" } },
        cargo = { allFeatures = true, buildScripts = { enable = true } },
        procMacro = { enable = true },
        inlayHints = {
          bindingModeHints = { enable = false },
          closureReturnTypeHints = { enable = "with_block" },
          lifetimeElisionHints = { enable = "skip_trivial" },
          parameterHints = { enable = true },
          typeHints = { enable = true },
        },
      },
    },
  },
  dap = lldb_dap ~= "" and {
    adapter = {
      type = "executable",
      command = lldb_dap,
      name = "lldb",
    },
  } or nil,
}

-- Pinned to the major that is actually installed and tested here. Getting this
-- range wrong is silent until the next vim.pack.update(), which would then
-- "upgrade" to a lower major and change the API under the config.
vim.pack.add({
  { src = "https://github.com/mrcjkb/rustaceanvim", version = vim.version.range("9") },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end

    -- Deliberately short. Neovim 0.12 already maps grn (rename), gra (code
    -- action), grr (references), gri (implementation), grt (type definition),
    -- grx (codelens) and gO (document symbol), plus K for hover. Re-mapping
    -- `gr` on top of those is what made every one of them wait out timeoutlen.
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    -- <leader>cd and not <leader>ds: <leader>d is the nvim-dap group, and a
    -- diagnostic float listed among the breakpoint commands reads as a debugger
    -- action. It belongs next to cf/cl/ch.
    map("<leader>cd", vim.diagnostic.open_float, "Diagnostic under cursor")

    -- Errors only. Walking every hint on a TypeScript buffer is unusable.
    map("]d", function()
      vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
    end, "Next error")
    map("[d", function()
      vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
    end, "Previous error")

    -- Inlay hints change how much of a Rust or Go signature you have to hold in
    -- your head. They also add visual noise while writing, hence the toggle.
    if client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
      map("<leader>ch", function()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = args.buf })
      end, "Toggle inlay hints")
    end

    if client:supports_method("textDocument/documentHighlight") then
      local highlight = vim.api.nvim_create_augroup("dotfiles.lsp.highlight." .. args.buf, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = highlight,
        buffer = args.buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = highlight,
        buffer = args.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

-- Import housekeeping, dispatched on whichever server is attached.
--
-- vtsls exposes these as workspace commands and there is no vim.lsp.buf wrapper
-- for them, so they go through executeCommand. tsgo has no executeCommand at
-- all — a request with no matching client is a silent no-op, not an error — but
-- does offer the standard source.* code action kinds.
--
-- Both routes work on vtsls, and the command one is used there on purpose: the
-- code action it returns carries a follow-up `_typescript.didOrganizeImports`
-- that vtsls then reports as unsupported, printing a warning on every use after
-- the edit has already applied correctly.
local function organize(command, kind)
  return function()
    if next(vim.lsp.get_clients({ bufnr = 0, name = "vtsls" })) then
      vim.lsp.buf_request(0, "workspace/executeCommand", {
        command = command,
        arguments = { vim.uri_from_bufnr(0) },
      })
    elseif kind then
      vim.lsp.buf.code_action({ context = { only = { kind }, diagnostics = {} }, apply = true })
    end
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  callback = function(args)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end
    map("<leader>co", organize("typescript.organizeImports", "source.organizeImports"), "Organize imports")
    -- nil kind: tsgo offers no source.addMissingImports, so under tsgo this is a
    -- no-op rather than an unrelated code action picker.
    map("<leader>cm", organize("typescript.addMissingImports", nil), "Add missing imports")
    map("<leader>cu", organize("typescript.removeUnusedImports", "source.removeUnusedImports"), "Remove unused imports")
    -- Applies only eslint's own fixAll action, without opening the picker.
    map("<leader>ca", function()
      vim.lsp.buf.code_action({
        context = { only = { "source.fixAll.eslint" }, diagnostics = {} },
        apply = true,
      })
    end, "Fix all eslint")
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "rust",
  callback = function(args)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end
    -- All of these are rustaceanvim commands, not generic LSP: there is no
    -- vim.lsp.buf equivalent for any of them.
    -- rust-analyzer runs cargo check/clippy on WRITE, never on keystroke: it is
    -- a full compilation and doing it per character would peg a core. This is
    -- the manual trigger for when you want the clippy pass without saving.
    -- Type errors do not need it — those come from rust-analyzer's own
    -- analysis, which does update as you type.
    map("<leader>cc", "<Cmd>RustLsp flyCheck run<CR>", "Run cargo check/clippy now")
    map("<leader>cR", "<Cmd>RustLsp runnables<CR>", "Runnables")
    map("<leader>ce", "<Cmd>RustLsp expandMacro<CR>", "Expand macro")
    map("<leader>cp", "<Cmd>RustLsp parentModule<CR>", "Parent module")
    map("<leader>cD", "<Cmd>RustLsp openDocs<CR>", "Open docs.rs")
    map("<leader>cC", "<Cmd>RustLsp openCargo<CR>", "Open Cargo.toml")
    -- Grouped actions; rust-analyzer nests them and the generic picker flattens
    -- the nesting away.
    map("<leader>cA", "<Cmd>RustLsp codeAction<CR>", "Rust code action")
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "json", "jsonc" },
  callback = function(args)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end
    -- jq and not the LSP: jsonls validates and completes against a schema but
    -- has no opinion on shape. `%!` filters the whole buffer through the
    -- command, so a failed parse leaves an error in the buffer and `u` undoes it.
    map("<leader>cp", "<Cmd>%!jq .<CR>", "Pretty-print with jq")
    map("<leader>cm", "<Cmd>%!jq -c .<CR>", "Minify with jq")
    map("<leader>cs", "<Cmd>%!jq -S .<CR>", "Sort keys with jq")
  end,
})
