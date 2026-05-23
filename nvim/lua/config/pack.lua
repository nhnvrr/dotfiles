-- Plugins pinned to a stable branch or semver tag where available.
-- Plain strings track the default branch (HEAD).
vim.pack.add({
	-- colorscheme (no tags, tracks main)
	"https://github.com/webhooked/kanso.nvim",

	-- treesitter (parser installation only; main branch is the new architecture, keep on master)
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "master" },

	-- fuzzy finder: fzf-lua (usa binario fzf nativo, sin plenary, sin build steps)
	"https://github.com/ibhagwan/fzf-lua",

	-- lsp & mason
	{ src = "https://github.com/williamboman/mason.nvim", version = "stable" },
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",

	-- formatting
	{ src = "https://github.com/stevearc/conform.nvim", version = "stable" },

	-- git
	{ src = "https://github.com/lewis6991/gitsigns.nvim", version = "release" },

	-- editing
	{ src = "https://github.com/kylechui/nvim-surround", version = "v4.0.4" },
	{ src = "https://github.com/windwp/nvim-autopairs", version = "0.10.0" },
	"https://github.com/windwp/nvim-ts-autotag",
	{ src = "https://github.com/gbprod/substitute.nvim", version = "v2.0.0" },
	{ src = "https://github.com/folke/flash.nvim", version = "stable" },

	-- diagnostics
	{ src = "https://github.com/folke/trouble.nvim", version = "stable" },

	-- tmux
	{ src = "https://github.com/christoomey/vim-tmux-navigator", version = "v1.0" },

	-- dap
	"https://github.com/mfussenegger/nvim-dap",
	"https://github.com/rcarriga/nvim-dap-ui",
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/theHamsta/nvim-dap-virtual-text",
	"https://github.com/jay-babu/mason-nvim-dap.nvim",
})

-- Theme
require("kanso").setup({ minimal = true })
vim.cmd.colorscheme("kanso-zen")
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#8a9a7b" })

-- Plugin setup calls (simple opts-only plugins)
require("mason").setup({
	ui = {
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
})

require("mason-tool-installer").setup({
	ensure_installed = {
		-- lsp servers
		"lua-language-server",
		"typescript-language-server",
		"html-lsp",
		"css-lsp",
		"tailwindcss-language-server",
		"emmet-ls",
		"prisma-language-server",
		"eslint-lsp",
		"yaml-language-server",
		"marksman",
		-- formatters
		"prettierd",
		"stylua",
		-- debuggers
		"js-debug-adapter",
	},
	run_on_start = true,
})

require("nvim-surround").setup()
require("nvim-autopairs").setup()
require("nvim-ts-autotag").setup()
require("substitute").setup()
require("flash").setup()
require("gitsigns").setup({
	on_attach = function(bufnr)
		local gs = require("gitsigns")
		local opts = { buffer = bufnr }

		vim.keymap.set("n", "]h", gs.next_hunk, vim.tbl_extend("force", opts, { desc = "Next hunk" }))
		vim.keymap.set("n", "[h", gs.prev_hunk, vim.tbl_extend("force", opts, { desc = "Prev hunk" }))
		vim.keymap.set("n", "<leader>hs", gs.stage_hunk, vim.tbl_extend("force", opts, { desc = "Stage hunk" }))
		vim.keymap.set("n", "<leader>hr", gs.reset_hunk, vim.tbl_extend("force", opts, { desc = "Reset hunk" }))
		vim.keymap.set("n", "<leader>hp", gs.preview_hunk, vim.tbl_extend("force", opts, { desc = "Preview hunk" }))
		vim.keymap.set("n", "<leader>hb", gs.blame_line, vim.tbl_extend("force", opts, { desc = "Blame line" }))
	end,
})

require("trouble").setup({ focus = true })

-- fzf-lua: usa fzf nativo, sin plenary, sin build steps.
-- register_ui_select enruta vim.ui.select (code actions, etc.) por fzf.
local fzf = require("fzf-lua")
fzf.setup({
	"default",
	winopts = { height = 0.85, width = 0.85, preview = { layout = "flex" } },
	files = {
		fd_opts = "--type f --hidden --follow --exclude .git",
	},
	grep = {
		-- ripgrep con exclusiones a nivel de la herramienta (no post-filtro en Lua)
		rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden "
			.. "--glob=!.git/ --glob=!node_modules/ --glob=!dist/ --glob=!.DS_Store",
	},
	keymap = {
		-- ctrl-j/k para navegar, ctrl-q manda la selección al quickfix list.
		fzf = {
			["ctrl-j"] = "down",
			["ctrl-k"] = "up",
			["ctrl-q"] = "select-all+accept",
		},
	},
})
fzf.register_ui_select()
