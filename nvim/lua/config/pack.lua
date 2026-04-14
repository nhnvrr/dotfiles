vim.pack.add({
	-- colorscheme
	"https://github.com/webhooked/kanso.nvim",

	-- treesitter (parser installation only, highlighting is built-in)
	"https://github.com/nvim-treesitter/nvim-treesitter",

	-- fuzzy finder
	"https://github.com/ibhagwan/fzf-lua",

	-- lsp & mason
	"https://github.com/williamboman/mason.nvim",
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",

	-- formatting
	"https://github.com/stevearc/conform.nvim",

	-- git
	"https://github.com/lewis6991/gitsigns.nvim",

	-- editing
	"https://github.com/kylechui/nvim-surround",
	"https://github.com/windwp/nvim-autopairs",
	"https://github.com/windwp/nvim-ts-autotag",
	"https://github.com/gbprod/substitute.nvim",
	"https://github.com/folke/flash.nvim",


	-- diagnostics
	"https://github.com/folke/trouble.nvim",

	-- tmux
	"https://github.com/christoomey/vim-tmux-navigator",
})

-- Theme
require("kanso").setup({ transparent = true })
vim.cmd.colorscheme("kanso-mist")
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
		"gopls",
		-- formatters
		"prettierd",
		"stylua",
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

-- fzf-lua
require("fzf-lua").register_ui_select()
require("fzf-lua").setup({
	winopts = { preview = { layout = "vertical", vertical = "down:50%" } },
	keymap = {
		fzf = {
			["ctrl-j"] = "down",
			["ctrl-k"] = "up",
			["ctrl-q"] = "select-all+accept",
		},
	},
	files = { fd_opts = "--type f --hidden --exclude .git --exclude node_modules" },
	grep = { rg_opts = "--hidden --glob '!.git/' --glob '!node_modules/' --column --line-number --no-heading --color=always --smart-case" },
})
