--- Display-level keys: the resolution toggle and moving a window between
--- monitors.

local M = {}

local RESOLUTIONS = {
  { w = 1512, h = 982 },
  { w = 1800, h = 1169 },
}

function M.toggleResolution()
  local screen = hs.screen.mainScreen()
  local cur = screen:currentMode()
  local target = cur.w == RESOLUTIONS[1].w and RESOLUTIONS[2] or RESOLUTIONS[1]

  if screen:setMode(target.w, target.h, 2, cur.freq, cur.depth) then
    hs.alert.show(("%dx%d"):format(target.w, target.h))
  else
    hs.alert.show(("Could not apply %dx%d"):format(target.w, target.h))
  end
end

--- Throws the focused window at the next (`delta > 0`) or previous display.
--- Size and relative position are kept and clamped into the new screen, so a
--- window does not come back half off the edge of a smaller monitor.
function M.moveToScreen(delta)
  local win = hs.window.focusedWindow()
  if not win then return end
  if #hs.screen.allScreens() < 2 then
    -- Said out loud rather than silently ignored: a key that does nothing is
    -- indistinguishable from a key that is broken.
    hs.alert.show("one display")
    return
  end
  local target = delta > 0 and win:screen():next() or win:screen():previous()
  win:moveToScreen(target, false, true)
end

return M
