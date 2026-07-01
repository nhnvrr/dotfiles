-- Tema: OneDark (dark-only). Antes había sync light/dark con Alacritty vía
-- ~/.config/theme-mode + fs-watcher; se dejó fijo, así que el theme es único y
-- los comandos zsh `light`/`dark` aplican el mismo OneDark.
local M = {}

function M.setup()
	require("onedark").setup({
		style = "dark",
		-- transparent: usa el fondo del terminal → matchea Alacritty (#1b1d23, sólido).
		transparent = true,
		term_colors = true,
		-- fondo más negro que el default de OneDark (#282c34), consistente con Alacritty.
		colors = { bg0 = "#1b1d23", bg1 = "#1b1d23" },
	})
	-- nvim-tree: color semántico OneDark para todos los estados git (icono + nombre).
	-- Solo fg para no romper la transparencia. Autocmd → sobrevive a los re-apply de
	-- `light`/`dark`.
	local function nvimtree_git_hl()
		local map = {
			Dirty = "#E5C07B", -- yellow → modificado
			Staged = "#98C379", -- green  → staged
			New = "#98C379", -- green  → nuevo/untracked
			Deleted = "#E06C75", -- red    → borrado
			Renamed = "#56B6C2", -- cyan   → renombrado
			Merge = "#D19A66", -- orange → conflicto
			Ignored = "#5C6370", -- gray   → ignorado
		}
		for state, color in pairs(map) do
			vim.api.nvim_set_hl(0, "NvimTreeGit" .. state .. "Icon", { fg = color })
			vim.api.nvim_set_hl(0, "NvimTreeGitFile" .. state .. "HL", { fg = color })
		end
	end
	vim.api.nvim_create_autocmd("ColorScheme", { pattern = "onedark", callback = nvimtree_git_hl })

	vim.o.background = "dark"
	require("onedark").load()
end

return M
