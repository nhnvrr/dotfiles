--- Light/dark only. No palette: Neovim's built-in colorscheme reads
--- `background`, so switching the mode is the whole job and there is nothing
--- here to keep in sync with the terminal.

local M = {}

local STATE = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")
local STATE_FILE = STATE .. "/mate/appearance"
local SOCKET_DIR = STATE .. "/mate/nvim"

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
	vim.o.background = mode == "light" and "light" or "dark"
	M.applied = vim.o.background
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
