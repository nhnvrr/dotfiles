--- Every new window of every app with a Dock icon opens at the same size: the
--- full main screen minus the gap, the frame cmd+alt+0 gives. macOS remembers a
--- window's frame on its own only when the app saves it on quit, and the
--- Electron apps (VS Code, Claude, Docker) and cmd+W both lose it.

local frame = require("mate.frame")

local M = {}

--- kind() == 1 is an app with a Dock icon, the same test zoomAll uses. Kept on
--- the module for the life of the config: a filter nothing references is
--- collected and stops firing.
M.filter = hs.window.filter.new(function(win)
  local app = win:application()
  return app ~= nil and app:kind() == 1 and app:bundleID() ~= "org.hammerspoon.Hammerspoon"
end)

M.filter:subscribe(hs.window.filter.windowCreated, function(win)
  if not win or not win:isStandard() then return end
  frame.placeWindow(win, frame.frameFor(0, 0, 1, 1, frame.GAP))
end)

return M
