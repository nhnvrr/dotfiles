vim.diagnostic.config({
	severity_sort = true,
	virtual_text = { severity = vim.diagnostic.severity.ERROR, prefix = "●", source = "if_many" },
	float = { source = "if_many" },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "E",
			[vim.diagnostic.severity.WARN] = "W",
			[vim.diagnostic.severity.INFO] = "I",
			[vim.diagnostic.severity.HINT] = "H",
		},
	},
})

vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })

local ts_inlay_hints = {
	parameterNames = { enabled = "literals" },
	parameterTypes = { enabled = true },
	variableTypes = { enabled = true },
	propertyDeclarationTypes = { enabled = true },
	functionLikeReturnTypes = { enabled = true },
	enumMemberValues = { enabled = true },
}

vim.lsp.config("vtsls", {
	settings = {
		typescript = {
			updateImportsOnFileMove = { enabled = "always" },
			preferences = { importModuleSpecifier = "shortest" },
			inlayHints = ts_inlay_hints,
		},
		javascript = { inlayHints = ts_inlay_hints },
		vtsls = { autoUseWorkspaceTsdk = true },
	},
})

vim.lsp.config("gopls", {
	settings = {
		gopls = {
			gofumpt = true,
			usePlaceholders = true,
			staticcheck = true,
			analyses = { unusedparams = true, nilness = true, shadow = true, unusedwrite = true },
			hints = {
				assignVariableTypes = true,
				compositeLiteralFields = true,
				constantValues = true,
				parameterNames = true,
				rangeVariableTypes = true,
			},
		},
	},
})

vim.lsp.config("rust_analyzer", {
	settings = {
		["rust-analyzer"] = {
			check = { command = "clippy", extraArgs = { "--no-deps" } },
			cargo = { allFeatures = true, buildScripts = { enable = true } },
			procMacro = { enable = true },
			inlayHints = {
				closureReturnTypeHints = { enable = "with_block" },
				lifetimeElisionHints = { enable = "skip_trivial" },
			},
		},
	},
})

-- The schema catalogue is a large table and costs ~1.8ms to require. before_init
-- runs when the client actually starts, so opening a Go file never pays for it.
vim.lsp.config("yamlls", {
	before_init = function(_, config)
		config.settings.yaml.schemas = require("schemastore").yaml.schemas()
	end,
	settings = {
		yaml = {
			keyOrdering = false,
			schemaStore = { enable = false, url = "" },
		},
		redhat = { telemetry = { enabled = false } },
	},
})

vim.lsp.config("jsonls", {
	before_init = function(_, config)
		config.settings.json.schemas = require("schemastore").json.schemas()
	end,
	settings = {
		json = { validate = { enable = true } },
	},
})

vim.lsp.config("eslint", {
	settings = { format = false },
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			workspace = { library = { vim.env.VIMRUNTIME .. "/lua", "${3rd}/luv/library" }, checkThirdParty = false },
			diagnostics = { globals = { "vim" } },
			hint = { enable = true },
		},
	},
})

vim.lsp.enable({ "vtsls", "eslint", "gopls", "rust_analyzer", "yamlls", "jsonls", "lua_ls", "bashls", "taplo" })

vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("dotfiles.lsp", { clear = true }),
	pattern = "*.go",
	callback = function(args)
		local client = vim.lsp.get_clients({ bufnr = args.buf, name = "gopls" })[1]
		if not client then
			return
		end
		local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
		params.context = { only = { "source.organizeImports" }, diagnostics = {} }
		local result = client:request_sync("textDocument/codeAction", params, 1000, args.buf)
		for _, action in ipairs(result and result.result or {}) do
			if action.edit then
				vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
			end
		end
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("dotfiles.lsp.attach", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end
		local function map(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
		end
		-- nvim 0.11 already binds grn, gra, grr, gri, grt and gO, but they land in
		-- the quickfix list. Routing the ones that return a list through fzf-lua
		-- gives a picker with a preview instead, and keeps the same keys.
		local function pick(name)
			return function()
				require("fzf-lua")[name]()
			end
		end
		map("gd", pick("lsp_definitions"), "Definition")
		map("gD", vim.lsp.buf.declaration, "Declaration")
		map("grr", pick("lsp_references"), "References")
		map("gri", pick("lsp_implementations"), "Implementation")
		map("grt", pick("lsp_typedefs"), "Type definition")

		map("<leader>cd", vim.diagnostic.open_float, "Diagnostic")
		-- ]d walks everything, ]e only the errors. Before, ]d skipped warnings
		-- silently and there was no way to reach them.
		map("]d", function()
			vim.diagnostic.jump({ count = 1 })
		end, "Next diagnostic")
		map("[d", function()
			vim.diagnostic.jump({ count = -1 })
		end, "Previous diagnostic")
		map("]e", function()
			vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
		end, "Next error")
		map("[e", function()
			vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
		end, "Previous error")
		if client:supports_method("textDocument/hover") then
			map("<leader>ci", vim.lsp.buf.hover, "Info (hover)")
		end
		if client:supports_method("textDocument/signatureHelp") then
			map("<leader>cs", vim.lsp.buf.signature_help, "Signature")
		end
		if client:supports_method("textDocument/inlayHint") then
			map("<leader>ch", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }), { bufnr = args.buf })
			end, "Toggle inlay hints")
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("dotfiles.lsp.ts", { clear = true }),
	pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
	callback = function(args)
		local function action(kind)
			return function()
				vim.lsp.buf.code_action({ context = { only = { kind }, diagnostics = {} }, apply = true })
			end
		end
		vim.keymap.set(
			"n",
			"<leader>co",
			action("source.organizeImports"),
			{ buffer = args.buf, desc = "Organize imports" }
		)
		vim.keymap.set(
			"n",
			"<leader>cm",
			action("source.addMissingImports"),
			{ buffer = args.buf, desc = "Add missing imports" }
		)
		vim.keymap.set(
			"n",
			"<leader>ca",
			action("source.fixAll.eslint"),
			{ buffer = args.buf, desc = "Fix all eslint" }
		)
	end,
})
