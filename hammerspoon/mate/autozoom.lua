--- Every new window opens at full screen: the same rectangle cmd+alt+F gives.
--- windowCreated and not the application watcher it replaces -- `launched` fires
--- once per app, so a second window never got placed.

local frame = require("mate.frame")

local M = {}

local SKIP = {
	["org.hammerspoon.Hammerspoon"] = true,
}

local function maximise(win)
	if not win or not win:isStandard() or win:isMinimized() or win:isFullScreen() then
		return
	end

	local app = win:application()
	local bid = app and app:bundleID()
	-- claimed: a layout is about to place this window itself, and the two writes race.
	-- kind() == 1 is an app with a Dock icon, the same test hideOthers uses.
	if not bid or SKIP[bid] or frame.claimed[bid] or app:kind() ~= 1 then
		return
	end

	local screen = win:screen()
	if not screen then
		return
	end

	frame.placeWindow(win, frame.frameFor(0, 0, 1, 1, frame.GAP, screen))
end

--- `true` is every window of every app; the default filter carries an exclusion
--- list. Held on the module or Hammerspoon collects it and placement stops.
M.filter = hs.window.filter.new(true)
M.filter:subscribe(hs.window.filter.windowCreated, function(win)
	maximise(win)
end)

return M
