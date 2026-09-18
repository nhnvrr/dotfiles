--- Keeps Alacritty on the same side of light/dark as macOS. Zed and herdr are
--- handled by `mate auto` itself.

local M = {}

local MATE_DIR = hs.fs.pathToAbsolute(hs.configdir .. "/mate")
local SCRIPT = MATE_DIR and (MATE_DIR .. "/../../bin/mate")

local function apply()
	if not SCRIPT then
		hs.printf("mate: cannot resolve %s/mate", hs.configdir)
		return
	end
	hs.task
		.new(SCRIPT, function(code, out, err)
			if code ~= 0 then
				hs.printf("mate auto failed (%d): %s", code, err or out or "")
			end
		end, { "auto" })
		:start()
end

M.watcher = hs.distributednotifications.new(function()
	-- The notification lands before the defaults database is updated.
	hs.timer.doAfter(0.2, apply)
end, "AppleInterfaceThemeChangedNotification")

M.watcher:start()
apply()

return M
