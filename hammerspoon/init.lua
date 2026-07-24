-- Layouts de dos apps y zoom, por atajo de teclado.
-- Regla: nunca esperar un tiempo fijo, esperar a que la condición sea cierta.

hs.window.animationDuration = 0

require("hs.ipc")
if hs.ipc and hs.ipc.cliInstall then hs.ipc.cliInstall() end

local log = hs.logger.new("layouts", "info")

if not hs.accessibilityState(true) then
  hs.alert.show("⚠️  Hammerspoon necesita Accessibility.\n" ..
    "Settings → Privacy & Security → Accessibility → Hammerspoon ON", { textSize = 18 }, 8)
end

-- Bundle IDs, no nombres de display: "Visual Studio Code" internamente es
-- "Code" y hs.application.find falla callado.
local APPS = {
  chrome    = "com.google.Chrome",
  ghostty   = "com.mitchellh.ghostty",
  zed       = "dev.zed.Zed",
  tableplus = "com.tinyapp.TablePlus",
}

local GAP = 2

-- ─── Primitivas ───────────────────────────────────────────────────

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

-- 4px de tolerancia: varias apps no aplican exacto el frame pedido.
local function frameMatches(a, b)
  return math.abs(a.w - b.w) < 4 and math.abs(a.h - b.h) < 4
     and math.abs(a.x - b.x) < 4 and math.abs(a.y - b.y) < 4
end

-- mainWindow() puede dar nil o un diálogo en vez de la ventana real.
local function windowOf(app)
  if not app then return nil end
  local win = app:mainWindow()
  if win and win:isStandard() then return win end
  for _, w in ipairs(app:allWindows()) do
    if w:isStandard() then return w end
  end
  return nil
end

-- Electron maneja AXSize y AXPosition por separado, así que setFrame() a veces
-- aplica solo una. Se parte en dos y se verifica. El corte es un deadline, no
-- un contador de intentos: contar intentos castigaba al caso lento (app fría).
local function applyFrame(win, rect, deadline)
  deadline = deadline or (hs.timer.secondsSinceEpoch() + 2)
  win:setSize(hs.geometry.size(rect.w, rect.h))
  win:setTopLeft(hs.geometry.point(rect.x, rect.y))

  hs.timer.doAfter(0.1, function()
    if not win:isVisible() then return end
    if frameMatches(win:frame(), rect) then return end
    if hs.timer.secondsSinceEpoch() >= deadline then log.w("no se pudo posicionar") return end
    applyFrame(win, rect, deadline)
  end)
end

-- macOS ignora setSize en native-fullscreen. Salir del Space es animado, así
-- que se espera a que isFullScreen() sea falso en vez de adivinar el tiempo.
local function placeWindow(win, rect)
  if not win:isFullScreen() then applyFrame(win, rect) return end
  win:setFullScreen(false)
  waitFor(function() return not win:isFullScreen() end,
    function() applyFrame(win, rect) end, 3)
end

-- ─── Colocación ───────────────────────────────────────────────────

-- Apps que un layout está colocando; el watcher las saltea para no pisarle
-- el frame.
local claimed = {}

-- Un solo camino para los cuatro casos: no corre, corre escondida, corre sin
-- ventanas, corre con ventana. Tratarlos por separado producía el bug de la
-- app abierta sin ventanas: quedaba un placement esperando un evento
-- `launched` que no llegaba nunca, porque la app ya estaba corriendo.
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

-- ─── Layouts ──────────────────────────────────────────────────────

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

-- Esconde todo MENOS las dos apps del layout. Antes escondía todo y después
-- las volvía a mostrar: ese hide→unhide era la causa de tener que apretar el
-- atajo dos veces, porque el setSize llegaba con la app todavía escondida.
local function sideBySide(left, right, leftW)
  currentLayout = { left = left, right = right, leftW = leftW }
  hideAllExcept({ left, right })
  placeApp(right, frameFor(leftW, 0, 1 - leftW, 1, GAP))
  placeApp(left, frameFor(0, 0, leftW, 1, GAP), function(win) win:focus() end)
end

local function rotateLayout()
  if not currentLayout then return end
  sideBySide(currentLayout.right, currentLayout.left, currentLayout.leftW)
end

-- ─── Auto-maximizar al abrir ──────────────────────────────────────

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

-- ─── Zoom toggle ──────────────────────────────────────────────────

local savedFrames = {}

local function toggleZoom()
  local win = hs.window.focusedWindow()
  if not win then return end

  -- Limpiar ids de ventanas ya cerradas; antes esta tabla crecía para siempre.
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

-- ─── Modos de workspace ───────────────────────────────────────────
-- Resolución + dock en un solo atajo. Los valores son los "looks like" de
-- System Settings → Displays, con scale 2 (Retina).

-- setMode pide los cinco parámetros. freq y depth se reusan del modo actual:
-- es el mismo panel físico, así que valen para cualquiera de las dos escalas.
-- Devuelve false si el modo no existe; el original no lo miraba y fallaba en
-- silencio. `availableModes()` reporta 0 en macOS 27, así que este chequeo es
-- la única forma de enterarse.
local function setResolution(w, h)
  local screen = hs.screen.mainScreen()
  local cur = screen:currentMode()
  if not screen:setMode(w, h, 2, cur.freq, cur.depth) then
    hs.alert.show(("No se pudo aplicar %dx%d"):format(w, h))
    return false
  end
  return true
end

-- Autohide del dock en vivo, sin reiniciarlo. Necesita permiso de Automation
-- para System Events (macOS lo pide la primera vez).
local function setDockAutohide(hidden)
  hs.osascript.applescript(
    ('tell application "System Events" to set autohide of dock preferences to %s')
      :format(hidden and "true" or "false"))
end

-- ⌃⌥⌘0 — Default: UI más grande, dock visible, y esconde todas las apps.
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "0", function()
  setResolution(1512, 982)
  setDockAutohide(false)
  hideAllExcept({})
  hs.alert.show("Default · dock visible · apps ocultas")
end)

-- ⌃⌥⌘9 — More Space: UI más chica, más área útil, dock oculto.
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "9", function()
  setResolution(1800, 1169)
  setDockAutohide(true)
  hs.alert.show("More Space · dock oculto")
end)

-- ─── Atajos ───────────────────────────────────────────────────────

hs.hotkey.bind({ "cmd", "alt" }, "1", function() sideBySide(APPS.zed, APPS.chrome, 0.7) end)
hs.hotkey.bind({ "cmd", "alt" }, "2", function() sideBySide(APPS.ghostty, APPS.chrome, 0.7) end)
hs.hotkey.bind({ "cmd", "alt" }, "3", function() sideBySide(APPS.tableplus, APPS.zed, 0.5) end)
hs.hotkey.bind({ "cmd", "alt" }, "R", rotateLayout)
hs.hotkey.bind({ "cmd", "alt" }, "F", toggleZoom)
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", hs.reload)

hs.alert.show("Hammerspoon cargado")
