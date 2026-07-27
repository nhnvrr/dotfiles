hs.window.animationDuration = 0

require("hs.ipc")
if hs.ipc and hs.ipc.cliInstall then hs.ipc.cliInstall() end

local log = hs.logger.new("layouts", "info")

if not hs.accessibilityState(true) then
  hs.alert.show("⚠️  Hammerspoon needs Accessibility.\n" ..
    "Settings → Privacy & Security → Accessibility → Hammerspoon ON", { textSize = 18 }, 8)
end

local APPS = {
  chrome    = "com.google.Chrome",
  ghostty = "com.mitchellh.ghostty",
  vscode    = "com.microsoft.VSCode",
  tableplus = "com.tinyapp.TablePlus",
}

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
  if not win:isFullScreen() then applyFrame(win, rect) return end
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

local NEVER_HIDE = {
  ["com.apple.finder"] = true,
  ["org.hammerspoon.Hammerspoon"] = true,
}

local function hideAllExcept(keep)
  local keepSet = {}
  for _, bid in ipairs(keep) do keepSet[bid] = true end
  for _, app in ipairs(hs.application.runningApplications()) do
    local bid = app:bundleID()
    if bid and not keepSet[bid] and not NEVER_HIDE[bid] and app:kind() == 1 then
      app:hide()
    end
  end
end

local currentLayout = nil

local function splitFrames(leftW, narrowActualW)
  local f = hs.screen.mainScreen():frame()
  local narrowOnLeft = leftW < 0.5
  local ratio = narrowOnLeft and leftW or (1 - leftW)
  local narrowW = narrowActualW or ((f.w - GAP) * ratio - GAP)
  local wideW = f.w - narrowW - GAP * 2
  local y, h = f.y + GAP / 2, f.h - GAP

  local narrowX, wideX
  if narrowOnLeft then
    narrowX = f.x + GAP / 2
    wideX = narrowX + narrowW + GAP
  else
    narrowX = f.x + f.w - GAP / 2 - narrowW
    wideX = f.x + GAP / 2
  end
  return hs.geometry.rect(narrowX, y, narrowW, h),
         hs.geometry.rect(wideX, y, wideW, h),
         narrowOnLeft
end

local function sideBySide(left, right, leftW)
  currentLayout = { left = left, right = right, leftW = leftW }
  hideAllExcept({ left, right })

  local narrowRect, _, narrowOnLeft = splitFrames(leftW)
  local narrowApp = narrowOnLeft and left or right
  local wideApp = narrowOnLeft and right or left

  placeApp(narrowApp, narrowRect, function(narrowWin)
    local n2, w2 = splitFrames(leftW, narrowWin:frame().w)
    placeWindow(narrowWin, n2)
    placeApp(wideApp, w2, function(wideWin)
      local focusWin = narrowOnLeft and narrowWin or wideWin
      focusWin:focus()
    end)
  end)
end

local function rotateLayout()
  if not currentLayout then return end
  local left, right = currentLayout.right, currentLayout.left
  local leftW = 1 - currentLayout.leftW

  local leftWin = windowOf(hs.application.get(left))
  local rightWin = windowOf(hs.application.get(right))
  if not (leftWin and rightWin) then sideBySide(left, right, leftW) return end

  currentLayout = { left = left, right = right, leftW = leftW }

  local narrowOnLeft = leftW < 0.5
  local narrowWin = narrowOnLeft and leftWin or rightWin
  local wideWin = narrowOnLeft and rightWin or leftWin
  local narrowRect, wideRect = splitFrames(leftW, narrowWin:frame().w)

  placeWindow(narrowWin, narrowRect)
  placeWindow(wideWin, wideRect)
  leftWin:focus()
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

hs.hotkey.bind({ "cmd", "alt" }, "1", function() sideBySide(APPS.vscode, APPS.chrome, 0.7) end)
hs.hotkey.bind({ "cmd", "alt" }, "2", function() sideBySide(APPS.ghostty, APPS.chrome, 0.7) end)
hs.hotkey.bind({ "cmd", "alt" }, "3", function() sideBySide(APPS.tableplus, APPS.chrome, 0.7) end)
hs.hotkey.bind({ "cmd", "alt" }, "R", rotateLayout)
hs.hotkey.bind({ "cmd", "alt" }, "F", toggleZoom)
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", hs.reload)

hs.alert.show("Hammerspoon loaded")
