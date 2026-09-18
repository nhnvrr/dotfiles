--- luna is dark-only, so light mode is its own palette re-solved in
--- mate/light.lua and fed back through on_colors.

local M = {}

local STATE = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")
local STATE_FILE = STATE .. "/mate/appearance"
local SOCKET_DIR = STATE .. "/mate/nvim"

local DARK_BG = "#1f1f1f"
local LIGHT_BG = "#f2f1ee"

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

function M.apply(mode)
	local light = mode == "light"
	local map = light and require("mate.light") or nil
	local bg = light and LIGHT_BG or DARK_BG

	vim.o.background = light and "light" or "dark"
	require("luna").setup({
		on_colors = function(c)
			local blend = require("luna.util").blend
			if map then
				-- Recursive: git and diag are nested tables of their own.
				local function swap(t)
					for k, v in pairs(t) do
						if type(v) == "table" then
							swap(v)
						elseif type(v) == "string" then
							t[k] = map[v] or v
						end
					end
				end
				swap(c)
			end
			c.bg = bg
			-- luna/palette.lua blends these against bg and stores the result, so a
			-- new bg does not reach them.
			c.line_nr = blend(c.grey_warm, 0.45, c.bg)
			c.git.add.bg = blend(c.ok, 0.14, c.bg)
			c.git.change.bg = blend(c.signal, 0.10, c.bg)
			c.git.text.bg = blend(c.signal, 0.30, c.bg)
			-- luna's #7c7c7c is 3.95:1 here; lifted to clear the 4.5:1 floor.
			c.comment = light and "#6e6e6e" or "#868686"
		end,
	})
	vim.cmd.colorscheme("luna")
	M.applied = mode
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
