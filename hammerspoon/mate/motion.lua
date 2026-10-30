--- What the keys do: drop the focused window in a pane, or put every window
--- at full screen. The panes follow the window's own screen — see the note at
--- the top of frame.lua.

local frame = require("mate.frame")

local GAP = frame.GAP

local M = {}

--- The external display's split: the working app wide on the left, a chat
--- column on the right. 0.69 is Rex measured on the LG after being dragged to
--- where it reads best, Slack fills what is left. On the built-in
--- display the column would be too narrow to use, so there it is the halves.
local WIDE = 0.69
M.panes = {
  h = { wide = { 0, 0, WIDE, 1 },        half = { 0, 0, 0.5, 1 } },
  l = { wide = { WIDE, 0, 1 - WIDE, 1 }, half = { 0.5, 0, 0.5, 1 } },
}

local function isExternal(screen)
  return not (screen:name() or ""):match("Built%-in")
end

--- cmd+alt+- / cmd+alt+= — the focused window into the left or right pane.
function M.pane(key)
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen()
  local p = isExternal(screen) and M.panes[key].wide or M.panes[key].half
  frame.placeWindow(win, frame.frameFor(p[1], p[2], p[3], p[4], GAP, screen))
end

--- cmd+alt+0 — every window of every running app at full screen, same gap as
--- the panes. Nothing is launched.
---
--- The focused window is restored at the end; unhiding steals focus otherwise.
function M.zoomAll()
  local rect = frame.frameFor(0, 0, 1, 1, GAP)
  local focused = hs.window.focusedWindow()

  for _, app in ipairs(hs.application.runningApplications()) do
    -- kind() == 1: an app with a Dock icon. Agents and UI elements have no
    -- window to place.
    if app:kind() == 1 and app:bundleID() ~= "org.hammerspoon.Hammerspoon" then
      if app:isHidden() then app:unhide() end
      for _, win in ipairs(app:allWindows()) do
        if win:isStandard() and not win:isMinimized() then
          frame.placeWindow(win, rect)
        end
      end
    end
  end

  if focused then focused:focus() end
end

return M
