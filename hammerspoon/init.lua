hs.window.animationDuration = 0

require("hs.ipc")
if hs.ipc and hs.ipc.cliInstall then hs.ipc.cliInstall() end

local log = hs.logger.new("layouts", "info")

if not hs.accessibilityState(true) then
  hs.alert.show("⚠️  Hammerspoon needs Accessibility.\n" ..
    "Settings → Privacy & Security → Accessibility → Hammerspoon ON", { textSize = 18 }, 8)
end

local APPS = {
  helium    = "net.imput.helium",
  chrome    = "com.google.Chrome",
  terminal  = "org.alacritty",
  vscode    = "com.microsoft.VSCode",
  datagrip  = "com.jetbrains.datagrip",
}

-- The right pane is bound to whichever of these is actually installed, in this
-- order, and not to one hardcoded bundle ID. That is what makes swapping the
-- browser a Brewfile edit rather than a Hammerspoon edit, and it keeps the pane
-- working on a machine that still has both during a transition.
--
-- Resolved once at load: pathForBundleID hits Launch Services, and this runs on
-- every cmd+alt+1/2/3 otherwise. Reload Hammerspoon after installing a browser.
local BROWSER_PREFERENCE = { APPS.helium, APPS.chrome }

local function firstInstalled(bundleIDs)
  for _, id in ipairs(bundleIDs) do
    -- Compared against "" and not just truthiness: the docs say the return is
    -- "string or nil", but for an app that is not installed it is the empty
    -- string, which Lua treats as true. Checking only `if path then` picks the
    -- first candidate every time, installed or not.
    local path = hs.application.pathForBundleID(id)
    if path and path ~= "" then
      return id
    end
  end
  -- Nothing installed: fall back to the last one so the caller still gets a
  -- string, and placeApp simply finds no window rather than erroring.
  return bundleIDs[#bundleIDs]
end

local GAP = 2
local function waitFor(cond, onReady, timeout)
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

local function frameFor(xR, yR, wR, hR, gap)
  gap = gap or 0
  local f = hs.screen.mainScreen():frame()
  local fx, fy = f.x + gap / 2, f.y + gap / 2
  local fw, fh = f.w - gap, f.h - gap
  return hs.geometry.rect(fx + fw * xR + gap / 2, fy + fh * yR + gap / 2,
    fw * wR - gap, fh * hR - gap)
end

local function frameMatches(a, b)
  return math.abs(a.w - b.w) < 4 and math.abs(a.h - b.h) < 4
     and math.abs(a.x - b.x) < 4 and math.abs(a.y - b.y) < 4
end

local function windowOf(app)
  if not app then return nil end
  local win = app:mainWindow()
  if win and win:isStandard() then return win end
  for _, w in ipairs(app:allWindows()) do
    if w:isStandard() then return w end
  end
  return nil
end

local function applyFrame(win, rect, deadline, previous)
  deadline = deadline or (hs.timer.secondsSinceEpoch() + 2)
  win:setSize(hs.geometry.size(rect.w, rect.h))
  win:setTopLeft(hs.geometry.point(rect.x, rect.y))

  hs.timer.doAfter(0.1, function()
    if not win:isVisible() then return end
    local current = win:frame()
    if frameMatches(current, rect) then return end
    if previous and frameMatches(current, previous) then
      log.i("window won't take that frame (own minimum size); leaving it where it landed")
      return
    end
    if hs.timer.secondsSinceEpoch() >= deadline then log.w("could not position window") return end
    applyFrame(win, rect, deadline, current)
  end)
end

local function placeWindow(win, rect)
  if not win:isFullScreen() then
    -- Load-bearing: swapping the left pane must not rewrite the right one.
    if frameMatches(win:frame(), rect) then return end
    applyFrame(win, rect)
    return
  end
  win:setFullScreen(false)
  waitFor(function() return not win:isFullScreen() end,
    function() applyFrame(win, rect) end, 3)
end

local claimed = {}

local function placeApp(bundleID, rect, onPlaced)
  claimed[bundleID] = true

  local app = hs.application.get(bundleID)
  if not app then
    hs.application.launchOrFocusByBundleID(bundleID)
  else
    if app:isHidden() then app:unhide() end
    if not windowOf(app) then hs.application.launchOrFocusByBundleID(bundleID) end
  end

  waitFor(function()
    local a = hs.application.get(bundleID)
    if not a or a:isHidden() then return nil end
    return windowOf(a)
  end, function(win)
    placeWindow(win, rect)
    claimed[bundleID] = nil
    if onPlaced then onPlaced(win) end
  end, 8)

  hs.timer.doAfter(9, function() claimed[bundleID] = nil end)
end

local RIGHT_PANE = firstInstalled(BROWSER_PREFERENCE)
local RIGHT_RATIO = 0.3

local function rightPaneIsPlaced(win)
  local f = hs.screen.mainScreen():frame()
  local r = win:frame()
  return math.abs((r.x + r.w) - (f.x + f.w - GAP / 2)) < 4
     and math.abs(r.h - (f.h - GAP)) < 4
     and r.w < f.w / 2
end

local function withRightPane(cb)
  local app = hs.application.get(RIGHT_PANE)
  local win = app and not app:isHidden() and windowOf(app) or nil
  if win and rightPaneIsPlaced(win) then
    win:raise()
    cb(win:frame())
    return
  end

  local f = hs.screen.mainScreen():frame()
  local w = (f.w - GAP) * RIGHT_RATIO - GAP
  placeApp(RIGHT_PANE, hs.geometry.rect(f.x + f.w - GAP / 2 - w, f.y + GAP / 2, w, f.h - GAP),
    function(placed)
      local got = placed:frame().w
      if got >= f.w / 2 then got = w end
      local rect = hs.geometry.rect(f.x + f.w - GAP / 2 - got, f.y + GAP / 2, got, f.h - GAP)
      placeWindow(placed, rect)
      placed:raise()
      cb(rect)
    end)
end

local function setLeftPane(bundleID)
  withRightPane(function(right)
    local f = hs.screen.mainScreen():frame()
    placeApp(bundleID,
      hs.geometry.rect(f.x + GAP / 2, f.y + GAP / 2, right.x - f.x - GAP * 1.5, f.h - GAP),
      function(win)
        win:raise()
        win:focus()
      end)
  end)
end

hs.application.watcher.new(function(_, event, app)
  if event ~= hs.application.watcher.launched then return end
  local bid = app:bundleID()
  if not bid or claimed[bid] or bid == "org.hammerspoon.Hammerspoon" then return end
  if app:kind() ~= 1 then return end

  local rect = frameFor(0, 0, 1, 1)
  waitFor(function() return windowOf(app) end, function(win)
    if claimed[bid] then return end
    placeWindow(win, rect)
  end, 5)
end):start()

local savedFrames = {}

local function toggleZoom()
  local win = hs.window.focusedWindow()
  if not win then return end

  for id in pairs(savedFrames) do
    if not hs.window.get(id) then savedFrames[id] = nil end
  end

  local id, full, current = win:id(), frameFor(0, 0, 1, 1), win:frame()
  if frameMatches(current, full) and savedFrames[id] then
    placeWindow(win, savedFrames[id])
    savedFrames[id] = nil
  else
    savedFrames[id] = current
    placeWindow(win, full)
  end
end

local RESOLUTIONS = {
  { w = 1512, h = 982 },
  { w = 1800, h = 1169 },
}

hs.hotkey.bind({ "cmd", "alt" }, "0", function()
  local screen = hs.screen.mainScreen()
  local cur = screen:currentMode()
  local target = cur.w == RESOLUTIONS[1].w and RESOLUTIONS[2] or RESOLUTIONS[1]

  if screen:setMode(target.w, target.h, 2, cur.freq, cur.depth) then
    hs.alert.show(("%dx%d"):format(target.w, target.h))
  else
    hs.alert.show(("Could not apply %dx%d"):format(target.w, target.h))
  end
end)

hs.hotkey.bind({ "cmd", "alt" }, "1", function() setLeftPane(APPS.vscode) end)
hs.hotkey.bind({ "cmd", "alt" }, "2", function() setLeftPane(APPS.terminal) end)
hs.hotkey.bind({ "cmd", "alt" }, "3", function() setLeftPane(APPS.datagrip) end)
hs.hotkey.bind({ "cmd" }, "`", function()
  local app = hs.application.get(APPS.terminal)
  if app and app:isFrontmost() then
    app:hide()
  else
    hs.application.launchOrFocusByBundleID(APPS.terminal)
  end
end)

hs.hotkey.bind({ "cmd", "alt" }, "F", toggleZoom)
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", hs.reload)

hs.alert.show("Hammerspoon loaded")
