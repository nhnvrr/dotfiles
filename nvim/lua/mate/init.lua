--- Light/dark switch. `bin/mate` writes the mode to a state file and pokes
--- this instance over a socket; the terminal flips its own palette from the
--- same run, so the two ends stay on the same sixteen colours.

local M = {}

local STATE = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")
local STATE_FILE = STATE .. "/mate/appearance"
local SOCKET_DIR = STATE .. "/mate/nvim"

--- One entry per mode. Dark is colors/mate.lua, built on alacritty's own
--- dark.toml, so it needs no corrections; light is upstream and gets a few.
local THEMES = {
	dark = {
		colorscheme = "mate",
	},
	light = {
		colorscheme = "github_light_high_contrast",
		-- The theme's own surface tokens (Folded, CursorLine). Its WinSeparator
		-- and FloatBorder ship as #20252c, a hard black rule much heavier than
		-- anything on the dark side; these keep both modes equally quiet.
		separator = 0xe7ecf0,
		-- Its ColorColumn is lighter than CursorLine, so the rule reads as a gap
		-- where the two cross. One step below it instead.
		color_column = 0xdde3e9,
		float_bg = 0xf0f1f2,
		float_fg = 0x66707b,
	},
}

function M.apply(mode)
	mode = mode == "light" and "light" or "dark"
	local theme = THEMES[mode]

	vim.o.background = mode
	vim.cmd.colorscheme(theme.colorscheme)

	-- termguicolors is on, so this only bites on a terminal without truecolor:
	-- there the ground stays the terminal's own and opacity keeps working.
	vim.cmd("hi Normal ctermbg=NONE")

	if theme.separator then
		vim.api.nvim_set_hl(0, "WinSeparator", { fg = theme.separator })
		vim.api.nvim_set_hl(0, "ColorColumn", { bg = theme.color_column })
		vim.api.nvim_set_hl(0, "NormalFloat", { bg = theme.float_bg })
		vim.api.nvim_set_hl(0, "FloatBorder", { fg = theme.float_fg, bg = theme.float_bg })
	end

	local marked = vim.api.nvim_get_hl(0, { name = "PMenu" })
	vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", {
		fg = marked.fg, bg = marked.bg,
		ctermfg = marked.ctermfg, ctermbg = marked.ctermbg,
		bold = true,
	})

	M.applied = mode
end

--- Written by bin/mate. Falls back to what nvim guessed from the terminal.
function M.mode()
	local fd = io.open(STATE_FILE, "r")
	if not fd then
		return vim.o.background
	end
	local word = (fd:read("l") or ""):gsub("%s", "")
	fd:close()
	return (word == "light" or word == "dark") and word or vim.o.background
end

local function sync()
	local mode = M.mode()
	if mode ~= M.applied then
		M.apply(mode)
	end
end

--- fs_event for the live flip, FocusGained for one that happened while nvim
--- was suspended.
function M.watch()
	local group = vim.api.nvim_create_augroup("MateAppearance", { clear = true })
	vim.api.nvim_create_autocmd("FocusGained", { group = group, callback = sync })

	local handle = vim.uv.new_fs_event()
	if handle then
		local ok = pcall(function()
			handle:start(STATE_FILE, {}, function()
				vim.schedule(sync)
			end)
		end)
		if ok then
			M.handle = handle
		end
	end

	-- A socket at a path `mate` can find, so it can poke this instance when
	-- the fs_event is not enough.
	vim.fn.mkdir(SOCKET_DIR, "p")
	local socket = SOCKET_DIR .. "/" .. vim.fn.getpid() .. ".sock"
	pcall(vim.fn.serverstart, socket)

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			if M.handle then
				pcall(function() M.handle:stop() end)
			end
			pcall(vim.fn.delete, socket)
		end,
	})

	vim.api.nvim_create_user_command("MateAppearance", function(opts)
		M.apply(opts.args ~= "" and opts.args or M.mode())
	end, { nargs = "?", complete = function() return { "light", "dark" } end })
end

return M
