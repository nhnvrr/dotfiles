--- Display-level keys: the resolution toggle and moving a window between
--- monitors.

local M = {}

-- The two largest HiDPI modes of the panel: Apple's default and "More Space"
-- on every Apple Silicon MacBook, whatever its size.
local function resolutions(screen)
  local seen, modes = {}, {}
  for _, m in pairs(screen:availableModes()) do
    local key = m.w .. "x" .. m.h
    if m.scale == 2 and not seen[key] then
      seen[key] = true
      modes[#modes + 1] = { w = m.w, h = m.h }
    end
  end
  table.sort(modes, function(a, b) return a.w > b.w end)
  return modes[2], modes[1]
end

function M.toggleResolution()
  local screen = hs.screen.mainScreen()
  local cur = screen:currentMode()
  local default, spacious = resolutions(screen)
  if not default then
    hs.alert.show("no HiDPI modes")
    return
  end
  local target = cur.w == default.w and spacious or default

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
