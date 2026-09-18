--- What the i3-style keys do to one window: move focus, drop it in a half,
--- centre it, change its width, zoom it. Every one of these follows the
--- window's own screen — see the note at the top of frame.lua.

local frame = require("mate.frame")

local GAP = frame.GAP

local M = {}

M.directions = {
  h = { focus = "focusWindowWest",  half = { 0, 0, 0.5, 1 } },
  l = { focus = "focusWindowEast",  half = { 0.5, 0, 0.5, 1 } },
  k = { focus = "focusWindowNorth", half = { 0, 0, 1, 0.5 } },
  j = { focus = "focusWindowSouth", half = { 0, 0.5, 1, 0.5 } },
}

--- nil, false, true: all windows as candidates, do not require frontmost, and
--- strict angle matching. Without strict, "west" also picks up windows merely
--- up-and-to-the-left, and focus jumps somewhere surprising on a busy screen.
function M.focus(key)
  local win = hs.window.focusedWindow()
  if win then win[M.directions[key].focus](win, nil, false, true) end
end

function M.half(key)
  local win = hs.window.focusedWindow()
  if not win then return end
  local h = M.directions[key].half
  frame.placeWindow(win, frame.frameFor(h[1], h[2], h[3], h[4], GAP, win:screen()))
end

--- Centred, at two thirds. The escape hatch for a window that belongs to
--- neither pane — a preferences sheet, a picker, anything being read rather
--- than worked in.
function M.centre()
  local win = hs.window.focusedWindow()
  if win then
    frame.placeWindow(win, frame.frameFor(1 / 6, 1 / 6, 2 / 3, 2 / 3, GAP, win:screen()))
  end
end

--- Width only: a horizontal split is the one this setup actually uses, and
--- binding both axes to one pair of keys guesses wrong half the time.
function M.resizeWidth(delta)
  local win = hs.window.focusedWindow()
  if not win then return end
  local f, screen = win:frame(), win:screen():frame()
  local w = math.max(screen.w * 0.2, math.min(screen.w - GAP * 2, f.w + delta))
  -- Anchored on whichever edge the window is already nearer, so a right-hand
  -- window grows leftward instead of walking off the screen. Both branches
  -- re-apply the gap: the left one used to keep whatever x the window had, so a
  -- window sitting flush against the edge stayed flush as it grew.
  local x = screen.x + GAP
  if math.abs((f.x + f.w) - (screen.x + screen.w)) < math.abs(f.x - screen.x) then
    x = screen.x + screen.w - GAP - w
  end
  frame.placeWindow(win, hs.geometry.rect(x, f.y, w, f.h))
end

local savedFrames = {}

function M.toggleZoom()
  local win = hs.window.focusedWindow()
  if not win then return end

  for id in pairs(savedFrames) do
    if not hs.window.get(id) then savedFrames[id] = nil end
  end

  local id = win:id()
  local full = frame.frameFor(0, 0, 1, 1, GAP, win:screen())
  local current = win:frame()
  if frame.frameMatches(current, full) and savedFrames[id] then
    frame.placeWindow(win, savedFrames[id])
    savedFrames[id] = nil
  else
    savedFrames[id] = current
    frame.placeWindow(win, full)
  end
end

return M
