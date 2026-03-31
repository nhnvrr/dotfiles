return {
	{
		"nhnvrr/nordaurora.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = true,
			dim_inactive = false,
			colors = {
				blue = "#81A1C1",
			},
			on_highlights = function(hl, c)
				hl.CursorLineNr = { fg = c.yellow, bold = false }
				hl.Comment = { fg = "#6c7a92", italic = true }
			end,
		},
		config = function(_, opts)
			require("nordaurora").setup(opts)
			vim.cmd.colorscheme("nordaurora")
		end,
	},
}
