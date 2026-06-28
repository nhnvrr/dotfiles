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
	vim.o.background = "dark"
	vim.cmd.colorscheme("nord")
end

return M
