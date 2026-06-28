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
  datagrip  = "com.jetbrains.datagrip",
  claude    = "com.anthropic.claudefordesktop",
}

-- ==================================================================
-- Window placement helpers
-- ==================================================================

-- Gap uniforme: la misma distancia entre ventana-ventana y ventana-borde,
-- arriba, abajo y a los costados. Insettamos primero el frame de pantalla
-- por GAP/2, después cada ventana por GAP/2 — total = GAP en cualquier
-- frontera. Subirlo a 8-12 para un look estilo Rectangle/yabai.
local GAP = 8

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
-- Gather aplica setSize a medias en una sola pasada — la ventana queda
-- a mitad de camino y hay que reintentar. Aplicamos el frame, verificamos
-- contra el objetivo y, si no cuadra (tolerancia 4px), reintentamos solo
-- hasta 6 veces. Así el atajo basta una vez sin insistir a mano.
local function applyFrame(win, rect, attempt)
  attempt = attempt or 1
  win:setSize(hs.geometry.size(rect.w, rect.h))
  win:setTopLeft(hs.geometry.point(rect.x, rect.y))
  if attempt >= 6 then return end
  hs.timer.doAfter(0.12, function()
    local fr = win:frame()
    local ok = math.abs(fr.w - rect.w) < 4 and math.abs(fr.h - rect.h) < 4
           and math.abs(fr.x - rect.x) < 4 and math.abs(fr.y - rect.y) < 4
    if not ok then applyFrame(win, rect, attempt + 1) end
  end)
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
    -- Una app escondida ignora setSize/setTopLeft: hay que mostrarla
    -- primero y darle al WindowServer un respiro para traer la ventana
    -- de vuelta antes de re-posicionarla. Sin esto, venir de un layout
    -- que escondió esta app obliga a pulsar el atajo dos veces.
    if app:isHidden() then
      app:unhide()
      hs.timer.doAfter(0.15, function()
        local win = app:mainWindow()
        if win then placeWindow(win, rect) end
        app:activate()
      end)
    else
      placeWindow(app:mainWindow(), rect)
      app:activate()
    end
    return
  end
  pendingPlacements[bundleID] = rect
  hs.application.launchOrFocusByBundleID(bundleID)
end

-- Apps que NO se auto-maximizan al arrancar. Agregá bundle IDs acá para
-- excluir (utilidades con ventanas chicas, paneles flotantes, etc.).
local AUTO_MAX_EXCLUDE = {
  ["org.hammerspoon.Hammerspoon"] = true,
}

-- Watcher único de lanzamiento. Cuando una app reporta `launched`:
--   • Si un layout dejó un placement pendiente, usamos ESE rect.
--   • Si no, la maximizamos al frame completo (menos GAP) — "todas las apps
--     arrancan a pantalla casi completa", dejando dock y menubar visibles.
-- El evento se dispara al arrancar el proceso, pero la ventana puede no estar
-- lista todavía (Chrome puede tardar ~800ms): polleamos con backoff acotado.
local appWatcher = hs.application.watcher.new(function(_, eventType, appObject)
  if eventType ~= hs.application.watcher.launched then return end
  local bid = appObject:bundleID()
  if not bid then return end

  -- Sin placement de layout: maximizamos solo apps con UI real (kind 1) y que
  -- no estén excluidas. Las del layout siguen su rect tal cual (no las filtra
  -- el kind/exclude, para no romper layouts si kind() se reporta tarde).
  local pending = pendingPlacements[bid]
  if not pending then
    if AUTO_MAX_EXCLUDE[bid] or appObject:kind() ~= 1 then return end
  end
  local rect = pending or frameFor(0, 0, 1, 1)

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
-- Layout "dev": Alacritty arriba-izq, Obsidian abajo-izq, Chrome a la derecha.
-- Columna izquierda 60% (Alacritty 60% alto / Obsidian 40%), Chrome 40% derecha.
hs.hotkey.bind({"cmd", "alt"}, "0", function()
  hideAllExcept({APPS.alacritty, APPS.obsidian, APPS.chrome})
  placeApp(APPS.alacritty, 0,   0,   0.6, 0.6)
  placeApp(APPS.obsidian,  0,   0.6, 0.6, 0.4)
  placeApp(APPS.chrome,    0.6, 0,   0.4, 1)
end)
hs.hotkey.bind({"cmd", "alt"}, "-", function()
  hideAllExcept({APPS.vscode, APPS.claude})
  placeApp(APPS.claude, 7/11, 0, 4/11, 1)
  placeApp(APPS.vscode, 0,    0, 7/11, 1)
end)
hs.hotkey.bind({"cmd", "alt"}, "9", function()
  hideAllExcept({APPS.datagrip, APPS.chrome})
  placeApp(APPS.datagrip, 0,   0, 0.5, 1)
  placeApp(APPS.chrome,  0.5, 0, 0.5, 1)
end)
-- Zoom toggle: ocupa el área disponible (sin dock/menubar, menos GAP) la
-- ventana enfocada; si ya está maximizada, la restaura a su tamaño previo.
local zoomPrev = {}
hs.hotkey.bind({"ctrl", "alt"}, "F", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local id = win:id()
  local target = frameFor(0, 0, 1, 1)
  local fr = win:frame()
  local isMax = math.abs(fr.w - target.w) < 4 and math.abs(fr.h - target.h) < 4
            and math.abs(fr.x - target.x) < 4 and math.abs(fr.y - target.y) < 4
  if isMax and zoomPrev[id] then
    applyFrame(win, zoomPrev[id])
    zoomPrev[id] = nil
  else
    zoomPrev[id] = fr
    placeWindow(win, target)
  end
end)

-- Terminal lateral: Alacritty en el 1/5 derecho y la app principal que estés
-- usando (VSCode, Chrome, DataGrip, Claude…) en el 4/5 restante a la izquierda.
-- Tomamos la ventana enfocada como "principal" antes de mover el foco al terminal.
hs.hotkey.bind({"ctrl", "alt"}, "M", function()
  local main = hs.window.focusedWindow()
  if main and main:application():bundleID() ~= APPS.alacritty then
    placeWindow(main, frameFor(0, 0, 4/5, 1))
  end
  placeApp(APPS.alacritty, 4/5, 0, 1/5, 1)
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", hs.reload)

hs.alert.show("Hammerspoon config loaded")
