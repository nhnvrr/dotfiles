-- Plugins pinned to a stable branch or semver tag where available.
-- Plain strings track the default branch (HEAD).
vim.pack.add({
	-- treesitter (parser installation only; main branch is the new architecture, keep on master)
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "master" },

	-- fuzzy finder: fzf-lua (usa binario fzf nativo, sin plenary, sin build steps)
	"https://github.com/ibhagwan/fzf-lua",

	-- icons (devicons) — los consumen fzf-lua, nvim-tree y lualine
	"https://github.com/nvim-tree/nvim-web-devicons",

	-- file explorer: nvim-tree (sidebar árbol, solo depende de devicons)
	"https://github.com/nvim-tree/nvim-tree.lua",

	-- statusline
	"https://github.com/nvim-lualine/lualine.nvim",

	-- theme
	"https://github.com/gbprod/nord.nvim",

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

-- Theme: Nord (dark-only)
require("config.theme").setup()

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

-- devicons: glyphs por filetype (los lee fzf-lua, nvim-tree y lualine). Necesita
-- una Nerd Font (IoskeleyMonoTerm ya lo es). color_icons → cada icono con su color.
require("nvim-web-devicons").setup({ color_icons = true })

-- nvim-tree: sidebar árbol. Deshabilitar netrw ANTES del setup (recomendado por
-- el plugin) para que no compita por abrir directorios.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require("nvim-tree").setup({
	hijack_cursor = true, -- el cursor sigue al nombre del archivo, no a la columna 0
	view = { width = 32, signcolumn = "yes" },
	renderer = {
		-- colapsa carpetas con un solo hijo (src/main/java → menos ruido).
		group_empty = true,
		-- sin la línea con la ruta absoluta arriba del árbol → más limpio.
		root_folder_label = false,
		-- líneas guía de indentación: jerarquía clara sin recargar.
		indent_markers = { enable = true },
		icons = {
			git_placement = "after",
			show = { file = true, folder = true, folder_arrow = true, git = true },
		},
	},
	-- mostrar dotfiles; respetar .gitignore lo maneja git, no el filtro.
	filters = { dotfiles = false, git_ignored = false },
	git = { enable = true },
	-- diagnostics LSP en el árbol, pero solo en archivos (no marcar carpetas enteras).
	diagnostics = { enable = true, show_on_dirs = false },
	actions = { open_file = { quit_on_open = false } },
})

-- lualine: statusline. theme "auto" toma los colores del colorscheme activo
-- (everforest) y se refresca solo al cambiar light/dark. globalstatus = una sola
-- barra global (reemplaza laststatus=3 del statusline manual anterior).
require("lualine").setup({
	options = {
		theme = "auto",
		globalstatus = true,
		section_separators = "",   -- sin separadores curvos → look plano y limpio
		component_separators = "",
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch" },
		lualine_c = {
			{ "filename", path = 1 }, -- ruta relativa al cwd
			{ "diagnostics", sources = { "nvim_diagnostic" } },
		},
		lualine_x = { "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	-- nvim-tree no necesita su propia barra; lualine la oculta ahí.
	extensions = { "nvim-tree" },
})

-- fzf-lua: usa fzf nativo, sin plenary, sin build steps.
-- register_ui_select enruta vim.ui.select (code actions, etc.) por fzf.
local fzf = require("fzf-lua")
fzf.setup({
	"default",
	-- iconos: file_icons (devicons por filetype) + git_icons (estado git) + color.
	defaults = { file_icons = true, git_icons = true, color_icons = true },
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
