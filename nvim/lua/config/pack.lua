vim.pack.add({
	-- colorscheme
	"https://github.com/webhooked/kanso.nvim",

	-- treesitter (parser installation only, highlighting is built-in)
	"https://github.com/nvim-treesitter/nvim-treesitter",

	-- telescope
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/nvim-lua/plenary.nvim",
	{ src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim", name = "telescope-fzf-native" },

	-- lsp & mason
	"https://github.com/williamboman/mason.nvim",
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",

	-- formatting
	"https://github.com/stevearc/conform.nvim",

	-- git
	"https://github.com/lewis6991/gitsigns.nvim",

	-- file tree
	"https://github.com/nvim-neo-tree/neo-tree.nvim",
	"https://github.com/MunifTanjim/nui.nvim",

	-- editing
	"https://github.com/kylechui/nvim-surround",
	"https://github.com/windwp/nvim-autopairs",
	"https://github.com/windwp/nvim-ts-autotag",
	"https://github.com/gbprod/substitute.nvim",
	"https://github.com/folke/flash.nvim",

	-- ui
	"https://github.com/nvim-lualine/lualine.nvim",
	"https://github.com/lukas-reineke/indent-blankline.nvim",
	"https://github.com/stevearc/dressing.nvim",

	-- diagnostics & todos
	"https://github.com/folke/trouble.nvim",
	"https://github.com/folke/todo-comments.nvim",

	-- dap
	"https://github.com/mfussenegger/nvim-dap",
	"https://github.com/rcarriga/nvim-dap-ui",
	"https://github.com/jay-babu/mason-nvim-dap.nvim",
	"https://github.com/nvim-neotest/nvim-nio",

	-- tmux
	"https://github.com/christoomey/vim-tmux-navigator",

	-- lazygit
	"https://github.com/kdheepak/lazygit.nvim",
})

-- Build telescope-fzf-native after install/update
vim.api.nvim_create_autocmd({ "PackChanged", "PackChangedPre" }, {
	callback = function(ev)
		if ev.data.spec.name == "telescope-fzf-native" then
			vim.system({ "make" }, { cwd = ev.data.path }):wait()
		end
	end,
})

-- Theme
require("kanso").setup({ transparent = false })
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
		"graphql-lsp",
		"emmet-ls",
		"prisma-language-server",
		"eslint-lsp",
		"yaml-language-server",
		"marksman",
		"gopls",
		-- formatters
		"prettier",
		"prettierd",
		"stylua",
		-- dap
		"js-debug-adapter",
	},
	run_on_start = true,
})

require("nvim-surround").setup()
require("nvim-autopairs").setup()
require("nvim-ts-autotag").setup()
require("substitute").setup()
require("flash").setup()
require("todo-comments").setup()
require("dressing").setup()
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

require("ibl").setup()
require("trouble").setup({ focus = true })
-- Neo-tree
require("neo-tree").setup({
	default_component_configs = {
		icon = {
			folder_closed = ">",
			folder_open = "v",
			folder_empty = "-",
			default = " ",
		},
		git_status = {
			symbols = {
				added = "+",
				modified = "~",
				deleted = "x",
				renamed = "r",
				untracked = "?",
				ignored = ".",
				unstaged = "u",
				staged = "s",
				conflict = "!",
			},
		},
	},
	filesystem = {
		filtered_items = {
			visible = false,
			hide_dotfiles = false,
			hide_gitignored = false,
		},
	},
	window = {
		mappings = {
			["l"] = "open",
			["h"] = "close_node",
			["v"] = "open_vsplit",
			["s"] = "open_split",
			["t"] = "open_tabnew",
		},
	},
})

-- Lualine
require("lualine").setup({
	options = {
		theme = "auto",
		globalstatus = true,
		icons_enabled = false,
		component_separators = "",
		section_separators = "",
	},
	sections = {
		lualine_a = {
			{
				"mode",
				padding = { left = 1, right = 1 },
				fmt = function(mode)
					local short = {
						NORMAL = "N",
						INSERT = "I",
						VISUAL = "V",
						["V-LINE"] = "VL",
						["V-BLOCK"] = "VB",
						REPLACE = "R",
						["V-REPLACE"] = "VR",
						COMMAND = "C",
						TERMINAL = "T",
						SELECT = "S",
						["S-LINE"] = "SL",
						["S-BLOCK"] = "SB",
					}
					return short[mode] or mode
				end,
			},
		},
		lualine_b = { "branch" },
		lualine_c = {
			{
				"filename",
				path = 1,
				shorting_target = 80,
				symbols = { modified = "[+]", readonly = "[ro]", unnamed = "[No Name]" },
			},
		},
		lualine_x = {
			{ "diagnostics", sources = { "nvim_diagnostic" } },
			{ "filetype", icon_only = false },
		},
		lualine_y = { "progress" },
		lualine_z = { { "location", padding = { left = 1, right = 1 } } },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
})

-- Telescope
local telescope = require("telescope")
local actions = require("telescope.actions")
local trouble_telescope = require("trouble.sources.telescope")

telescope.setup({
	defaults = {
		path_display = { "smart" },
		file_ignore_patterns = { "%.git/", "node_modules/" },
		mappings = {
			i = {
				["<C-k>"] = actions.move_selection_previous,
				["<C-j>"] = actions.move_selection_next,
				["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
				["<C-t>"] = trouble_telescope.open,
			},
		},
	},
	pickers = {
		find_files = { hidden = true },
		live_grep = {
			additional_args = function()
				return { "--hidden", "--glob", "!**/.git/*", "--glob", "!**/node_modules/*" }
			end,
		},
	},
})

-- Load fzf extension (may fail if not yet built)
local fzf_ok, _ = pcall(telescope.load_extension, "fzf")
if not fzf_ok then
	vim.notify("telescope-fzf-native: run :call vim.pack.update() to build", vim.log.levels.WARN)
end
