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
  chrome    = "com.google.Chrome",
  vscode    = "com.microsoft.VSCode",
  terminal  = "com.mitchellh.ghostty",
  tableplus = "com.tinyapp.TablePlus",
}

-- ==================================================================
-- Window placement helpers
-- ==================================================================

-- Gap uniforme entre ventana-ventana y ventana-borde, solo en layouts;
-- el auto-maximizado al abrir apps va sin gap (pantalla completa).
local LAYOUT_GAP = 2

local function frameFor(xR, yR, wR, hR, gap)
  gap = gap or 0
  local f = hs.screen.mainScreen():frame()
  local fx, fy = f.x + gap/2, f.y + gap/2
  local fw, fh = f.w - gap,   f.h - gap
  return hs.geometry.rect(
    fx + fw * xR + gap/2,
    fy + fh * yR + gap/2,
    fw * wR - gap,
    fh * hR - gap
  )
end

-- Apps Electron (VSCode, etc.) manejan AXSize y AXPosition por separado:
-- setFrame() a veces aplica solo posición. Partimos en setSize + setTopLeft,
-- con tamaño primero para que la posición opere sobre las dimensiones
-- finales. Algunas apps aplican setSize a medias en una sola pasada — la
-- ventana queda a mitad de camino y hay que reintentar. Aplicamos el frame,
-- verificamos contra el objetivo y, si no cuadra (tolerancia 4px),
-- reintentamos solo hasta 6 veces.
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

-- macOS ignora setSize si la ventana está en native-fullscreen: hay que
-- salir del Space fullscreen (transición animada, ~0.7s) antes de
-- posicionar. Solo el fullscreen real necesita el camino lento — una
-- ventana grande "zoomed" se resizea normal, y los reintentos de
-- applyFrame cubren cualquier caso terco.
local function placeWindow(win, rect)
  if win:isFullScreen() then
    win:setFullScreen(false)
    hs.timer.doAfter(0.7, function() applyFrame(win, rect) end)
  else
    applyFrame(win, rect)
  end
end

-- Cola para apps que están arrancando. El watcher las posiciona cuando
-- aparezca su ventana principal.
local pendingPlacements = {}

local function placeApp(bundleID, xR, yR, wR, hR, gap)
  local rect = frameFor(xR, yR, wR, hR, gap)
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
--   • Si no, la maximizamos al frame completo — "todas las apps arrancan
--     a pantalla completa", dejando dock y menubar visibles.
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

-- Apps que NUNCA escondemos: Finder mantiene el desktop y Hammerspoon
-- no se puede esconder a sí mismo.
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

-- Layout de dos apps lado a lado: `left` ocupa `leftW`, `right` el resto.
-- Primero se esconde TODO (incluidas las apps del layout) para una
-- transición limpia: la pantalla queda vacía y las dos apps aparecen ya
-- posicionadas — placeApp maneja el unhide. La app izquierda se posiciona
-- última → queda con el foco.
-- Guardamos el layout activo para poder rotarlo (⌘⌥R).
local currentLayout = nil

local function sideBySide(left, right, leftW)
  currentLayout = { left = left, right = right, leftW = leftW }
  hideAllExcept({})
  placeApp(right, leftW, 0, 1 - leftW, 1, LAYOUT_GAP)
  placeApp(left,  0,     0, leftW,     1, LAYOUT_GAP)
end

-- Rota el layout activo (⌘⌥R): las apps intercambian de lado, los frames
-- quedan iguales (en 70/30 la que estaba a la izquierda pasa al 30 derecho).
local function rotateLayout()
  if not currentLayout then return end
  sideBySide(currentLayout.right, currentLayout.left, currentLayout.leftW)
end

-- ==================================================================
-- Hotkeys
-- ==================================================================

hs.hotkey.bind({"cmd", "alt"}, "1", function() sideBySide(APPS.vscode,    APPS.chrome, 0.7) end)
hs.hotkey.bind({"cmd", "alt"}, "2", function() sideBySide(APPS.terminal,  APPS.chrome, 0.7) end)
hs.hotkey.bind({"cmd", "alt"}, "3", function() sideBySide(APPS.tableplus, APPS.vscode, 0.5) end)
hs.hotkey.bind({"cmd", "alt"}, "R", rotateLayout)

-- Zoom toggle de la ventana con foco (⌘⌥F): la maximiza a pantalla
-- completa (dock y menubar visibles) guardando su frame previo; si ya
-- está maximizada, la restaura a como estaba. La comparación usa
-- tolerancia 4px, igual que applyFrame, porque algunas apps no aplican
-- el frame pedido con exactitud.
local zoomedFrames = {}

hs.hotkey.bind({"cmd", "alt"}, "F", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local full = frameFor(0, 0, 1, 1)
  local fr = win:frame()
  local isZoomed = math.abs(fr.w - full.w) < 4 and math.abs(fr.h - full.h) < 4
               and math.abs(fr.x - full.x) < 4 and math.abs(fr.y - full.y) < 4
  local saved = zoomedFrames[win:id()]
  if isZoomed and saved then
    placeWindow(win, saved)
    zoomedFrames[win:id()] = nil
  else
    zoomedFrames[win:id()] = fr
    placeWindow(win, full)
  end
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", hs.reload)

hs.alert.show("Hammerspoon config loaded")
