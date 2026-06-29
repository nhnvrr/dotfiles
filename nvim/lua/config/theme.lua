-- Tema: Nord (dark-only). Antes había sync light/dark con Alacritty vía
-- ~/.config/theme-mode + fs-watcher; Nord no tiene light usable, así que el
-- theme es fijo y los comandos zsh `light`/`dark` aplican el mismo Nord.
local M = {}

function M.setup()
	require("nord").setup({
		-- transparent: usa el fondo del terminal → matchea Alacritty (sólido).
		transparent = true,
		terminal_colors = true,
	})
	-- nvim-tree: color semántico Nord para todos los estados git (icono + nombre).
	-- nord.nvim deja staged/renamed/merge fuera de paleta; los fijamos acá. Solo fg
	-- para no romper la transparencia. Autocmd → sobrevive a los re-apply de `light`/`dark`.
	local function nvimtree_git_hl()
		local map = {
			Dirty = "#EBCB8B", -- yellow → modificado
			Staged = "#A3BE8C", -- green  → staged
			New = "#A3BE8C", -- green  → nuevo/untracked
			Deleted = "#BF616A", -- red    → borrado
			Renamed = "#88C0D0", -- cyan   → renombrado
			Merge = "#D08770", -- orange → conflicto
			Ignored = "#616E88", -- gray   → ignorado
		}
		for state, color in pairs(map) do
			vim.api.nvim_set_hl(0, "NvimTreeGit" .. state .. "Icon", { fg = color })
			vim.api.nvim_set_hl(0, "NvimTreeGitFile" .. state .. "HL", { fg = color })
		end
	end
	vim.api.nvim_create_autocmd("ColorScheme", { pattern = "nord", callback = nvimtree_git_hl })

	vim.o.background = "dark"
	vim.cmd.colorscheme("nord")
end

return M
