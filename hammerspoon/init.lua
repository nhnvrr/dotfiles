-- ==================================================================
-- Hammerspoon init.lua — layouts y atajos de window-management
-- ==================================================================

-- Setup global -----------------------------------------------------
-- Resize instantáneo, sin animación.
hs.window.animationDuration = 0

-- IPC + AppleScript habilitados para diagnóstico remoto.
require("hs.ipc")
if hs.ipc and hs.ipc.cliInstall then hs.ipc.cliInstall() end
hs.allowAppleScript(true)

local log = hs.logger.new("layouts", "info")

-- Accessibility es requisito para mover ventanas de otras apps.
if not hs.accessibilityState(true) then
  hs.alert.show(
    "⚠️  Hammerspoon necesita Accessibility.\n" ..
    "Settings → Privacy & Security → Accessibility → Hammerspoon ON",
    { textSize = 18 }, 8
  )
end

-- Apps identificadas por bundle ID. Los nombres de display (ej. "Visual
-- Studio Code") no siempre coinciden con el nombre interno del bundle
-- (ej. "Code"), causando que hs.application.find falle silenciosamente.
-- Bundle IDs son estables y únicos.
local APPS = {
  gather    = "com.gather.Gather",
  slack     = "com.tinyspeck.slackmacgap",
  chrome    = "com.google.Chrome",
  vscode    = "com.microsoft.VSCode",
  alacritty = "org.alacritty",
  obsidian  = "md.obsidian",
  tableplus = "com.tinyapp.TablePlus",
  claude    = "com.anthropic.claudefordesktop",
}

-- ==================================================================
-- Window placement helpers
-- ==================================================================

-- Gap uniforme: la misma distancia entre ventana-ventana y ventana-borde,
-- arriba, abajo y a los costados. Insettamos primero el frame de pantalla
-- por GAP/2, después cada ventana por GAP/2 — total = GAP en cualquier
-- frontera. Subirlo a 8-12 para un look estilo Rectangle/yabai.
local GAP = 2

local function frameFor(xR, yR, wR, hR)
  local f = hs.screen.mainScreen():frame()
  local fx, fy = f.x + GAP/2, f.y + GAP/2
  local fw, fh = f.w - GAP,   f.h - GAP
  return hs.geometry.rect(
    fx + fw * xR + GAP/2,
    fy + fh * yR + GAP/2,
    fw * wR - GAP,
    fh * hR - GAP
  )
end

-- Apps Electron (Gather, Slack, VSCode) manejan AXSize y AXPosition por
-- separado: setFrame() a veces aplica solo posición. Partimos en setSize
-- + setTopLeft, con tamaño primero para que la posición opere sobre las
-- dimensiones finales.
local function applyFrame(win, rect)
  win:setSize(hs.geometry.size(rect.w, rect.h))
  win:setTopLeft(hs.geometry.point(rect.x, rect.y))
end

-- macOS ignora setSize si la ventana está en native-fullscreen o "zoomed"
-- (ocupa toda la pantalla útil pero no en un Space dedicado). Detectamos
-- ambos casos heurísticamente y salimos del estado antes de re-posicionar.
local function placeWindow(win, rect)
  local fr = win:frame()
  local sc = win:screen():frame()
  local zoomed = fr.w >= sc.w - 1 and fr.h >= sc.h - 1
  if win:isFullScreen() or zoomed then
    win:setFullScreen(false)
    hs.timer.doAfter(0.7, function() applyFrame(win, rect) end)
  else
    applyFrame(win, rect)
  end
end

-- Cola para apps que están arrancando. El watcher las posiciona cuando
-- aparezca su ventana principal.
local pendingPlacements = {}

local function placeApp(bundleID, xR, yR, wR, hR)
  local rect = frameFor(xR, yR, wR, hR)
  local app = hs.application.get(bundleID)
  if app and app:mainWindow() then
    placeWindow(app:mainWindow(), rect)
    app:activate()
    return
  end
  pendingPlacements[bundleID] = rect
  hs.application.launchOrFocusByBundleID(bundleID)
end

-- Watcher único: cuando una app con placement pendiente reporta `launched`,
-- polleamos su ventana principal con backoff acotado. El evento `launched`
-- se dispara cuando arranca el proceso, pero la ventana puede no estar
-- lista todavía (Chrome puede tardar ~800ms en mostrarla).
local appWatcher = hs.application.watcher.new(function(_, eventType, appObject)
  if eventType ~= hs.application.watcher.launched then return end
  local bid = appObject:bundleID()
  local rect = pendingPlacements[bid]
  if not rect then return end

  local attempts = 0
  local poll
  poll = hs.timer.doEvery(0.15, function()
    attempts = attempts + 1
    local win = appObject:mainWindow()
    if win then
      placeWindow(win, rect)
      appObject:activate()
      pendingPlacements[bid] = nil
      poll:stop()
    elseif attempts >= 30 then
      log.w("placement timeout for " .. bid)
      pendingPlacements[bid] = nil
      poll:stop()
    end
  end)
end)
appWatcher:start()

-- ==================================================================
-- Hide-all helper
-- ==================================================================

-- Apps que NUNCA escondemos: Finder mantiene el desktop, Hammerspoon
-- no se puede esconder a sí mismo, y los demás de la lista son menubar
-- helpers que serían molestos de ocultar.
local NEVER_HIDE = {
  ["com.apple.finder"] = true,
  ["org.hammerspoon.Hammerspoon"] = true,
}

-- Esconde todas las apps con UI excepto las pasadas en `keep` (lista de
-- bundle IDs). Filtramos por `app:kind() == 1` para tocar solo apps con
-- ventanas reales, no background services ni menubar widgets.
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

-- ==================================================================
-- Layouts
-- ==================================================================

-- LEFT = 1/4 (450px en 1800px) — apenas arriba del mínimo de Gather (400px)
-- y le deja 3/4 a Chrome/VSCode en el panel derecho.
local LEFT  = 1/4
local RIGHT = 3/4

local function layoutGatherWith(otherBundleID)
  hideAllExcept({APPS.gather, otherBundleID})
  placeApp(otherBundleID, 0,     0, RIGHT, 1)
  placeApp(APPS.gather,   RIGHT, 0, LEFT,  1)
end

local function zoom(bundleID)
  hideAllExcept({bundleID})
  placeApp(bundleID, 0, 0, 1, 1)
end

-- ==================================================================
-- Hotkeys
-- ==================================================================

hs.hotkey.bind({"cmd", "alt"}, "1", function() layoutGatherWith(APPS.chrome) end)
hs.hotkey.bind({"cmd", "alt"}, "2", function() layoutGatherWith(APPS.vscode) end)
hs.hotkey.bind({"cmd", "alt"}, "3", function() zoom(APPS.slack) end)
hs.hotkey.bind({"cmd", "alt"}, "4", function() zoom(APPS.obsidian) end)
hs.hotkey.bind({"cmd", "alt"}, "§", function() zoom(APPS.gather) end)
hs.hotkey.bind({"cmd", "alt"}, "0", function()
  hs.application.launchOrFocusByBundleID(APPS.alacritty)
end)
hs.hotkey.bind({"cmd", "alt"}, "-", function()
  hideAllExcept({APPS.alacritty, APPS.claude})
  placeApp(APPS.claude,    4/6, 0, 2/6, 1)
  placeApp(APPS.alacritty, 0,   0, 4/6, 1)
end)
hs.hotkey.bind({"cmd", "alt"}, "9", function()
  hideAllExcept({APPS.tableplus, APPS.chrome})
  placeApp(APPS.tableplus, 0,   0, 0.5, 1)
  placeApp(APPS.chrome,    0.5, 0, 0.5, 1)
end)
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", hs.reload)

hs.alert.show("Hammerspoon config loaded")
