-- Plugins pinned to a stable branch or semver tag where available.
-- Plain strings track the default branch (HEAD).
vim.pack.add({
	-- colorscheme (no tags, tracks main)
	"https://github.com/webhooked/kanso.nvim",

	-- treesitter (parser installation only; main branch is the new architecture, keep on master)
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "master" },

	-- fuzzy finder (tracks main)
	"https://github.com/ibhagwan/fzf-lua",
	"https://github.com/nvim-tree/nvim-web-devicons",

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

	-- database
	"https://github.com/tpope/vim-dadbod",
	"https://github.com/kristijanhusak/vim-dadbod-ui",
	"https://github.com/kristijanhusak/vim-dadbod-completion",

	-- dap
	"https://github.com/mfussenegger/nvim-dap",
	"https://github.com/rcarriga/nvim-dap-ui",
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/theHamsta/nvim-dap-virtual-text",
	"https://github.com/jay-babu/mason-nvim-dap.nvim",
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

-- vim-dadbod-ui
vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_show_help = 0
vim.g.db_ui_win_position = "left"
vim.g.db_ui_winwidth = 40
vim.g.db_ui_execute_on_save = 0  -- :w should only save, not run the query

-- Close every DBUI-related buffer at once (drawer + query buffers + result panes).
vim.api.nvim_create_user_command("DBCloseAll", function()
  local closed = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local ft = vim.bo[buf].filetype
      local has_dbui_marker = pcall(vim.api.nvim_buf_get_var, buf, "dbui_db_key_name")
      if ft == "dbui" or ft == "dbout" or has_dbui_marker then
        vim.api.nvim_buf_delete(buf, { force = true })
        closed = closed + 1
      end
    end
  end
  vim.notify(("Closed %d DBUI buffer(s)"):format(closed))
end, { desc = "Close every DBUI buffer (drawer, queries, results)" })

-- fzf-lua (telescope profile = horizontal preview, prompt at bottom, icons)
require("fzf-lua").register_ui_select()
require("fzf-lua").setup({
	"telescope",
	keymap = {
		fzf = {
			["ctrl-j"] = "down",
			["ctrl-k"] = "up",
			["ctrl-q"] = "select-all+accept",
		},
	},
	files = { fd_opts = "--type f --hidden --exclude .git --exclude node_modules --exclude .DS_Store" },
	grep = { rg_opts = "--hidden --glob '!.git/' --glob '!node_modules/' --glob '!.DS_Store' --column --line-number --no-heading --color=always --smart-case" },
})
