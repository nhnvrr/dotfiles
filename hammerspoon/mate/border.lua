--- The focus ring.
---
--- Hammerspoon has no border API, so the ring is an hs.canvas panel tracking the
--- focused window. It straddles the window edge, half in and half out, so a 3pt
--- ring spills 1.5 points into the GAP and never reaches the neighbour.
---
--- Two filled rectangles, not one stroked one: hs.canvas has no strokeGradient,
--- only fillGradient, so a gradient ring has to be a filled shape with its
--- middle punched out. The inner rectangle composites with `destinationOut`,
--- which clears the destination wherever the source is opaque.
---
--- The canvas never takes focus: it has no mouse callbacks, so AppKit leaves it
--- out of the responder chain.

local M = {}

--- Slots 4 and 12 as hexes, not indices: one hue across two tiers, ΔE 10.5, so
--- it reads as a sheen rather than as two colours meeting (ΔE 13.1). The only
--- hand-kept copy of alacritty/mate.toml left -- move it when that file moves.
---
--- On #1f1f1f they are 5.57:1 and 8.26:1; against white 3.19:1 and 2.28:1,
--- which is the cost of a mid-tier blue on a pale wallpaper.
---
--- 1.5pt wide, which on a 2x display is three device pixels and the thinnest
--- value that still renders as a line rather than as a grey smear. All the
--- geometry below derives from this, so it is the only number to change -- half
--- the ring lands in the GAP, which at 10 has room for far more than this.
---
--- alpha goes to 1 at this width and did not have to at 3. A thin line spends
--- most of its area on the antialiased edge, so 0.85 was taking a second bite
--- out of pixels the rasteriser had already faded -- the ring read as a
--- suggestion rather than an outline. Widen it again and 0.85 is fine.
local BORDER = {
  width = 1.5, radius = 10, alpha = 1.0,
  -- Slot 4 to slot 12. `angle` is degrees; 45 runs it corner to corner.
  colours = { "#5b9bd5", "#83bdf2" },
  angle = 45,
}

local border = hs.canvas.new({ x = 0, y = 0, w = 0, h = 0 })
border:level(hs.canvas.windowLevels.floating)
-- moveToActiveSpace and not canJoinAllSpaces: the latter is what drags the ring
-- into Mission Control, where it outlines the desktop instead of a window.
border:behavior(hs.canvas.windowBehaviors.moveToActiveSpace
  + hs.canvas.windowBehaviors.stationary)

-- Built once and mutated in place afterwards. replaceElements rebuilds the whole
-- element table, which is not something to do sixty times a second while a
-- window is being dragged.
--- The two radii are the window's own corner grown and shrunk by half the ring,
--- so the inside and the outside of the band stay concentric.
local HALF = BORDER.width / 2

border:replaceElements(
  {
    type = "rectangle",
    action = "fill",
    fillGradient = "linear",
    fillGradientAngle = BORDER.angle,
    fillGradientColors = {
      { hex = BORDER.colours[1], alpha = BORDER.alpha },
      { hex = BORDER.colours[2], alpha = BORDER.alpha },
    },
    roundedRectRadii = { xRadius = BORDER.radius + HALF, yRadius = BORDER.radius + HALF },
    frame = { x = 0, y = 0, w = 0, h = 0 },
  },
  {
    -- The hole. Its colour is irrelevant under destinationOut; only its alpha
    -- is read, and it has to be opaque to clear anything.
    type = "rectangle",
    action = "fill",
    compositeRule = "destinationOut",
    fillColor = { white = 1, alpha = 1 },
    roundedRectRadii = {
      xRadius = math.max(BORDER.radius - HALF, 0),
      yRadius = math.max(BORDER.radius - HALF, 0),
    },
    frame = { x = 0, y = 0, w = 0, h = 0 },
  }
)

local function paint(win)
  if not win or not win:isStandard() or win:isMinimized() or win:isFullScreen() then
    border:hide()
    return
  end
  local f, w = win:frame(), BORDER.width
  -- The canvas is the window grown by half a ring on every side. The gradient
  -- rectangle fills it edge to edge, and the hole is inset by a whole ring --
  -- half to reach the window edge and half again to cross the band -- which is
  -- what leaves the ring straddling the window's own outline.
  border:frame({ x = f.x - HALF, y = f.y - HALF, w = f.w + w, h = f.h + w })
  border[1].frame = { x = 0, y = 0, w = f.w + w, h = f.h + w }
  border[2].frame = { x = w, y = w, w = f.w - w, h = f.h - w }
  border:show()
end

-- A drag emits an AX notification per display frame. Throttled on the leading
-- edge with a trailing call, so the ring keeps up during the drag and still
-- lands on the final frame. A debounce would be the wrong tool: at sixty
-- notifications a second it never fires until the window stops moving.
local INTERVAL = 1 / 60
local lastPaint, pending = 0, nil

--- Suspended while a placement is in flight. The ring tracks windowMoved, which
--- an app emits after it has moved, so without this it outlines the old frame
--- for as long as the app takes to take the new one.
local suspended = false

local function schedule(win)
  if suspended then return end
  local now = hs.timer.secondsSinceEpoch()
  local wait = INTERVAL - (now - lastPaint)
  if wait <= 0 then
    lastPaint = now
    paint(win)
    return
  end
  if pending then return end
  pending = hs.timer.doAfter(wait, function()
    pending = nil
    lastPaint = hs.timer.secondsSinceEpoch()
    paint(hs.window.focusedWindow())
  end)
end

local function hide()
  if pending then pending:stop() pending = nil end
  border:hide()
end

function M.suspend()
  suspended = true
  hide()
end

function M.resume()
  suspended = false
  paint(hs.window.focusedWindow())
end

-- Every app, not just the terminal. AXStandardWindow is what keeps the ring off
-- panels, sheets and pickers, which have no frame worth tracing and move under
-- it anyway. Hammerspoon is rejected so its own console does not get a ring
-- while the border is being worked on.
M.filter = hs.window.filter.new(true)
  :setDefaultFilter({ allowRoles = "AXStandardWindow" })
  :rejectApp("Hammerspoon")

M.filter:subscribe({
  hs.window.filter.windowFocused,
  hs.window.filter.windowMoved,
  hs.window.filter.windowUnminimized,
  -- Without this the ring is left drawn over a window that has just gone
  -- fullscreen; paint() refuses to draw one, but it was never told.
  hs.window.filter.windowUnfullscreened,
}, schedule)

M.filter:subscribe({
  hs.window.filter.windowUnfocused,
  hs.window.filter.windowMinimized,
  hs.window.filter.windowDestroyed,
  hs.window.filter.windowNotVisible,
  hs.window.filter.windowFullscreened,
}, hide)

paint(hs.window.focusedWindow())

return M
