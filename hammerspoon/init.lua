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
