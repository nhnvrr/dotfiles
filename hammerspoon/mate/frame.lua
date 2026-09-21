--- Geometry and placement. Everything that computes a rectangle or puts a
--- window into one goes through here, so the gap convention lives in one place.
---
--- Which screen a frame belongs to:
---
---   window motions follow the window          layouts target the main screen
---   ────────────────────────────────          ──────────────────────────────
---   ctrl+alt+shift+h/j/k/l   halves           cmd+alt+1   the workspace
---   ctrl+alt+c               centre           cmd+alt+R   rotate it
---   ctrl+alt+-  /  =         width
---   cmd+alt+F                zoom
---        ──► win:screen()                          ──► mainScreen()
---
--- A layout is a statement about the workspace, so it stays on one deliberate
--- screen; a motion is a statement about the window in front of you, so it
--- follows that window. Moving a window between displays is ctrl+alt+, / .

local log = hs.logger.new("mate.frame", "info")

local M = {}

--- The gap, and it means the same thing everywhere: a window sits `GAP` off the
--- screen edge and two neighbours sit `GAP` apart. It used to be per-window
--- padding, which made the seam between two windows twice the outer margin --
--- 4 at the edge and 8 down the middle. frameFor splits it in half instead, see
--- there.
M.GAP = 6

--- Polls `cond` until it returns something truthy, then hands that value to
--- `onReady`. Gives up after `timeout` seconds (default 5).
function M.waitFor(cond, onReady, timeout)
  local ok = cond()
  if ok then onReady(ok) return end

  local elapsed, timer = 0, nil
  timer = hs.timer.doEvery(0.05, function()
    local value = cond()
    if value then timer:stop() onReady(value) return end
    elapsed = elapsed + 0.05
    if elapsed >= (timeout or 5) then timer:stop() log.w("timeout") end
  end)
end

--- A rectangle given as fractions of a screen, separated from everything around
--- it by `gap`. Half of the gap comes off the screen before the fractions are
--- taken and half off the slot afterwards, so the two halves meet at every
--- internal seam and add up to a full `gap` at the screen edge. That is what
--- keeps one number meaning one distance, and it still leaves no slot needing to
--- know what sits next to it.
---
---   screen 1600 wide, gap 10
---     usable   x = 5, w = 1590        inset by gap/2
---     left     x = 10, w = 785        slot 0..0.5, inset by gap/2
---     right    x = 805, w = 785
---     edge = 10     seam = 805 - 795 = 10
---
--- `screen` defaults to the main one; pass `win:screen()` for anything that
--- should follow the window rather than the workspace.
function M.frameFor(xR, yR, wR, hR, gap, screen)
  gap = gap or 0
  local half = gap / 2
  local s = (screen or hs.screen.mainScreen()):frame()
  local f = { x = s.x + half, y = s.y + half, w = s.w - gap, h = s.h - gap }
  return hs.geometry.rect(
    f.x + f.w * xR + half,
    f.y + f.h * yR + half,
    f.w * wR - gap,
    f.h * hR - gap)
end

function M.frameMatches(a, b)
  return math.abs(a.w - b.w) < 4 and math.abs(a.h - b.h) < 4
     and math.abs(a.x - b.x) < 4 and math.abs(a.y - b.y) < 4
end

function M.windowOf(app)
  if not app then return nil end
  local win = app:mainWindow()
  if win and win:isStandard() then return win end
  for _, w in ipairs(app:allWindows()) do
    if w:isStandard() then return w end
  end
  return nil
end

--- setFrame and not setSize followed by setTopLeft. The two-call form looks
--- equivalent and is not: an app whose accessibility implementation is slow
--- applies one of them and drops the other, and which one it drops depends on
--- the order. Measured against a browser going from full width to a half:
---
---   setSize then setTopLeft    x=902 w=1792   moved, never resized
---   setTopLeft then setSize    x=  4 w=1792   neither took
---   size, topLeft, size again  x=  4 w= 894   resized, never moved
---   setFrame                   x=902 w= 894   correct
---
--- `stalls` is the other half of the same bug. A window that has not moved
--- between two checks is usually a window that cannot take the frame — its own
--- minimum size — but it is also what a slow app looks like mid-apply, so
--- giving up on the first unchanged sample turns a delay into a permanent wrong
--- frame. Two in a row is the evidence; one is a guess.
local function applyFrame(win, rect, deadline, previous, stalls)
  deadline = deadline or (hs.timer.secondsSinceEpoch() + 2)
  win:setFrame(rect)

  -- Past the end of the slide: mid-animation the frame is an interpolated one,
  -- and checking there reads it as a stall and restarts the animation.
  hs.timer.doAfter(hs.window.animationDuration + 0.1, function()
    if not win:isVisible() then return end
    local current = win:frame()
    if M.frameMatches(current, rect) then return end

    local stalled = (previous and M.frameMatches(current, previous)) and (stalls or 0) + 1 or 0
    if stalled >= 2 then
      log.i("window won't take that frame (own minimum size); leaving it where it landed")
      return
    end

    if hs.timer.secondsSinceEpoch() >= deadline then
      log.w("could not position window")
      return
    end
    applyFrame(win, rect, deadline, current, stalled)
  end)
end

function M.placeWindow(win, rect)
  if not win:isFullScreen() then
    -- Load-bearing: a window already in its slot is left alone, so calling a
    -- layout twice costs nothing and only the halves that actually move move.
    if M.frameMatches(win:frame(), rect) then return end
    applyFrame(win, rect)
    return
  end
  win:setFullScreen(false)
  M.waitFor(function() return not win:isFullScreen() end,
    function() applyFrame(win, rect) end, 3)
end

--- Bundle IDs a layout is currently placing. mate/autozoom.lua skips these, so
--- its "every new window opens at full screen" rule does not fire on a window a
--- layout is about to position itself.
M.claimed = {}

function M.placeApp(bundleID, rect, onPlaced)
  M.claimed[bundleID] = true

  local app = hs.application.get(bundleID)
  if not app then
    hs.application.launchOrFocusByBundleID(bundleID)
  else
    if app:isHidden() then app:unhide() end
    if not M.windowOf(app) then hs.application.launchOrFocusByBundleID(bundleID) end
  end

  M.waitFor(function()
    local a = hs.application.get(bundleID)
    if not a or a:isHidden() then return nil end
    return M.windowOf(a)
  end, function(win)
    M.placeWindow(win, rect)
    M.claimed[bundleID] = nil
    if onPlaced then onPlaced(win) end
  end, 8)

  hs.timer.doAfter(9, function() M.claimed[bundleID] = nil end)
end

return M
