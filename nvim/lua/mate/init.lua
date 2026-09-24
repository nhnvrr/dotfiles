--- Light/dark switch. `bin/mate` writes the mode to a state file and pokes
--- this instance over a socket; the terminal flips its own palette from the
--- same run, so the two ends stay on the same sixteen colours.

local M = {}

local STATE = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")
local STATE_FILE = STATE .. "/mate/appearance"
local SOCKET_DIR = STATE .. "/mate/nvim"

--- One entry per mode: the scheme that matches the palette alacritty imports,
--- and the few groups that scheme leaves wrong. `swap` is the same correction
--- alacritty's own file makes -- the ground and the slots the scheme puts
--- under 4.5:1 on it -- and both files have to carry the same numbers.
local THEMES = {
	dark = {
		colorscheme = "black-metal-bathory",
		-- bathory grounds on #000000 -- halation at a full workday -- and is nearly
		-- monochrome: five greys, one orange, one teal. Lifting the ground alone is
		-- not enough. Its three darkest slots sit level with or below #1d2021, so
		-- the surfaces vanish and Comment goes to 1.30:1 unless they move too.
		--
		-- base01 is the one with two jobs: paper under CursorLine and PMenu, and
		-- ink in Search, IncSearch and PMenuSel. #2a2d2e is a 1.18 step off the
		-- ground as paper, and still 5.39:1 as ink on base0A.
		swap = {
			[0x000000] = 0x1d2021, -- base00 ground
			[0x121212] = 0x2a2d2e, -- base01 1.14 below the ground -> 1.18 above
			[0x222222] = 0x3a3d3e, -- base02 1.03, level with it -> 1.50
			[0x333333] = 0x8a8a8a, -- base03 Comment   1.30 -> 4.75
			[0x444444] = 0x949494, -- base0F Delimiter 1.68 -> 5.40
			[0x5f8787] = 0x6a9494, -- base08 red slot  4.14 -> 4.90
		},
		-- Pitched between base01 and base02: a float needs a ground one step
		-- off the buffer's, and a border above both.
		separator = 0x3a3d3e,
		-- bathory gives ColorColumn the same base01 as CursorLine, so the rule
		-- disappears on the line being edited. One step above it.
		color_column = 0x3a3d3e,
		float_bg = 0x2e3233,
		float_fg = 0x4a4f50,
		-- No comment_from: base03 is lifted in the swap above, which carries
		-- Comment to 4.75:1 along with LineNr and the rest of the chrome.
		--
		-- base16 gives these a bg meant for the signcolumn, and neo-tree copies
		-- it onto the filename -- a grey box behind every dirty entry. gitsigns
		-- and neo-tree both resolve through GitGutter*, so this fixes both.
		strip_gitgutter = true,
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
		-- No comment_from: this theme puts Comment at #4b535d, 7.8:1 on white.
	},
}

--- Patching Normal alone would leave every group that baked the same hex in,
--- so the swap walks the whole table. Linked groups are skipped: writing one
--- back would resolve the link and detach it from whatever it follows.
local function reslot(swap)
	for name, def in pairs(vim.api.nvim_get_hl(0, {})) do
		if not def.link then
			local touched = false
			for _, key in ipairs({ "fg", "bg", "sp" }) do
				local to = def[key] and swap[def[key]]
				if to then
					def[key], touched = to, true
				end
			end
			if touched then
				vim.api.nvim_set_hl(0, name, def)
			end
		end
	end
end

function M.apply(mode)
	mode = mode == "light" and "light" or "dark"
	local theme = THEMES[mode]

	vim.o.background = mode
	vim.cmd.colorscheme(theme.colorscheme)

	if theme.swap then
		reslot(theme.swap)
	end

	-- termguicolors is on, so this only bites on a terminal without truecolor:
	-- there the ground stays the terminal's own and opacity keeps working.
	vim.cmd("hi Normal ctermbg=NONE")

	vim.api.nvim_set_hl(0, "WinSeparator", { fg = theme.separator })
	vim.api.nvim_set_hl(0, "ColorColumn", { bg = theme.color_column })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = theme.float_bg })
	vim.api.nvim_set_hl(0, "FloatBorder", { fg = theme.float_fg, bg = theme.float_bg })

	if theme.strip_gitgutter then
		for _, group in ipairs({
			"GitGutterAdd", "GitGutterChange", "GitGutterDelete", "GitGutterChangeDelete",
		}) do
			local hl = vim.api.nvim_get_hl(0, { name = group })
			hl.bg, hl.ctermbg = nil, nil
			vim.api.nvim_set_hl(0, group, hl)
		end
	end

	if theme.comment_from then
		vim.api.nvim_set_hl(0, "Comment", vim.api.nvim_get_hl(0, { name = theme.comment_from }))
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
