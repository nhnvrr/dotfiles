-- cmd+§ (laptop, keycode 10) and cmd+` (US keyboard, keycode 50) cycle the
-- front app's windows. Raw keycodes: the layout decides which glyph each key has.
local function nextWindow()
  local app = hs.application.frontmostApplication()
  local wins = hs.fnutils.filter(hs.window.orderedWindows(), function(w)
    return w:application() == app
  end)
  if #wins > 1 then wins[#wins]:focus() end
end

hs.hotkey.bind({ 'cmd' }, 10, nextWindow)
hs.hotkey.bind({ 'cmd' }, 50, nextWindow)

-- cmd+alt+0: every visible window fills its screen, GAP px off each edge.
local GAP = 8
hs.hotkey.bind({ 'cmd', 'alt' }, '0', function()
  for _, w in ipairs(hs.window.visibleWindows()) do
    if w:isStandard() then
      local f = w:screen():frame()
      w:setFrame({ x = f.x + GAP, y = f.y + GAP, w = f.w - 2 * GAP, h = f.h - 2 * GAP }, 0)
    end
  end
end)

-- Orange outline around the focused window. Globals: a collected canvas or
-- filter silently stops drawing.
border = hs.canvas.new({ x = 0, y = 0, w = 0, h = 0 })
border:level(hs.canvas.windowLevels.overlay)
border:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
border[1] = {
  type = 'rectangle', action = 'stroke', strokeWidth = 4,
  strokeColor = { hex = '#d65d0e' },
  roundedRectRadii = { xRadius = 12, yRadius = 12 },
}

local function redraw()
  local w = hs.window.focusedWindow()
  if not w or not w:isStandard() or w:isFullScreen() then return border:hide() end
  border:frame(w:frame()):show()
end

windows = hs.window.filter.new()
windows:subscribe({
  hs.window.filter.windowFocused, hs.window.filter.windowMoved,
  hs.window.filter.windowUnfocused, hs.window.filter.windowDestroyed,
  hs.window.filter.windowMinimized, hs.window.filter.windowFullscreened,
}, redraw)
redraw()
