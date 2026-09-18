--- The workspace: what is on screen, and nothing else.
---
---   cmd+alt+1                      cmd+alt+2
---   +-----------+-----------+      +-----------+-----------+
---   |           |           |      |           |           |
---   | Terminal  |  Chrome   |      |  VS Code  |  Chrome   |
---   |           |           |      |           |           |
---   +-----------+-----------+      +-----------+-----------+
---
---   cmd+alt+3
---   +-----------+-----------+
---   |           |  Chrome   |
---   |  VS Code  +-----------+
---   |           | Terminal  |
---   +-----------+-----------+
---
--- Every layout hides every other application first and then places what it
--- owns, so the result is the same screen every time rather than whatever was
--- left over from the last one.
---
--- cmd+alt+R cycles the occupants one slot along — a swap with two, a rotation
--- with three — and nothing else: it does not hide, launch or unhide anything,
--- because by the time you rotate, everything is already up.
---
--- Hidden and not minimised. Hiding is per-application and instant; minimising
--- is per-window and runs the Dock's genie animation, which is the single
--- slowest thing a layout can ask macOS to do.

local apps     = require("mate.apps")
local frame    = require("mate.frame")

local GAP = frame.GAP

local M = {}

--- What the workspace is showing: bundle IDs, one per geometry slot. rotate()
--- cycles the list, and because the slot geometry is positional, that is the
--- whole of a rotation.
M.current = { apps.bundles.terminal, apps.bundles.browser }

--- The slots, left to right and top to bottom, for `n` occupants. Computed per
--- call: the resolution toggle on cmd+alt+0 changes them underneath, so they
--- cannot be cached at load.
local function geometryFor(n)
  if n == 3 then
    return {
      frame.frameFor(0, 0, 0.5, 1, GAP),
      frame.frameFor(0.5, 0, 0.5, 0.5, GAP),
      frame.frameFor(0.5, 0.5, 0.5, 0.5, GAP),
    }
  end
  return { frame.frameFor(0, 0, 0.5, 1, GAP), frame.frameFor(0.5, 0, 0.5, 1, GAP) }
end

--- The bundle IDs the current layout owns, which is what hideOthers spares and
--- what the launch watcher keeps its hands off.
local function ownedBundles()
  return M.current
end

--- Never hidden. Hammerspoon because hiding the thing running this would take
--- the alert and the focus ring with it, Finder because it owns the desktop and
--- hiding it buys nothing — it has no window in the way to begin with.
local KEEP = {
  ["org.hammerspoon.Hammerspoon"] = true,
  ["com.apple.finder"] = true,
}

local function hideOthers()
  local keep = {}
  for bid in pairs(KEEP) do keep[bid] = true end
  for _, bid in ipairs(ownedBundles()) do keep[bid] = true end

  for _, app in ipairs(hs.application.runningApplications()) do
    local bid = app:bundleID()
    -- kind() == 1 is an app with a Dock icon. Agents and UI elements have no
    -- window to hide, and calling hide() on each of them still costs an
    -- accessibility round trip on a key that is meant to feel instant.
    if bid and not keep[bid] and app:kind() == 1 and not app:isHidden() then
      app:hide()
    end
  end
end

--- Every standard window of `app` into `rect`, `primary` last so it ends up on
--- top. A slot belongs to an application, not to one of its windows: without
--- this, a second Terminal window opened by hand stays sitting over the
--- browser's half when cmd+alt+1 places the workspace.
---
--- Cheap to repeat, because frame.placeWindow returns early on a window already
--- in its slot — only the strays actually move.
local function stackInto(app, rect, primary)
  for _, win in ipairs(app:allWindows()) do
    if win:isStandard() and win ~= primary and not win:isMinimized() then
      frame.placeWindow(win, rect)
    end
  end
  frame.placeWindow(primary, rect)
  primary:raise()
end

--- Places one application, synchronously when it can. A running app keeps its
--- windows while hidden, so unhide() hands one back in the same tick and the
--- whole layout lands in a single frame. frame.placeApp is the fallback for the
--- one case that genuinely has to wait: an app that is not running yet.
local function placeApp(bid, rect, onPlaced)
  local app = hs.application.get(bid)
  if app then
    if app:isHidden() then app:unhide() end
    local win = frame.windowOf(app)
    if win then
      stackInto(app, rect, win)
      if onPlaced then onPlaced(win) end
      return
    end
  end

  frame.placeApp(bid, rect, function(win)
    local a = hs.application.get(bid)
    if a then stackInto(a, rect, win) else win:raise() end
    if onPlaced then onPlaced(win) end
  end)
end

--- Last slot first: raise() brings a window to the front, so placing slot 1 last
--- is what leaves the keyboard on the window the layout considers primary.
local function place()
  local targets = M.current
  local rects = geometryFor(#targets)

  for i = #targets, 1, -1 do
    local rect = rects[i]
    -- More occupants than slots: leave them alone rather than stack them.
    if rect then
      placeApp(targets[i], rect, i == 1 and function(win) win:focus() end or nil)
    end
  end
end

--- cmd+alt+1 — the terminal and the browser, half the screen each.
---
--- The pair is rebuilt only when the workspace is not already showing it, so
--- pressing it again after a rotation re-places the rotated arrangement rather
--- than snapping the two back to their declared sides.
function M.layout()
  local targets = M.current
  local isTerminalPair = #targets == 2
    and (targets[1] == apps.bundles.terminal or targets[2] == apps.bundles.terminal)

  if not isTerminalPair then
    M.current = { apps.bundles.terminal, apps.bundles.browser }
  end

  hideOthers()
  place()
end

--- cmd+alt+2 — VS Code on the left and the browser on the right. Unlike
--- cmd+alt+1, this is a distinct pair, so invoking it restores the declared
--- sides after a rotation.
function M.code()
  M.current = { apps.bundles.vscode, apps.bundles.browser }
  hideOthers()
  place()
end

--- cmd+alt+3 — VS Code takes the left half; the browser and the terminal split
--- the right half. Invoking it always restores that order after a rotation.
function M.development()
  M.current = { apps.bundles.vscode, apps.bundles.browser, apps.bundles.terminal }
  hideOthers()
  place()
end

--- cmd+alt+4 — Alacritty on the left half and Chrome on the right: cmd+alt+1
--- with the work browser, and the only layout that places Chrome.
function M.work()
  M.current = { apps.bundles.terminal, apps.bundles.chrome }
  hideOthers()
  place()
end

--- cmd+alt+§ — every app in apps.stack at full screen, same gap as the halves.
---
--- unhide is not optional: a hidden app returns an empty allWindows(), so there
--- is no window to place until it is back. Nothing is launched -- an app that is
--- not running is skipped, because a key that opens six apps is a different key.
---
--- The focused window is restored at the end; unhiding steals focus otherwise.
--- cmd+alt+1/2/3 are the way back, and they hide the rest again.
function M.zoomAll()
  local rect = frame.frameFor(0, 0, 1, 1, GAP)
  local focused = hs.window.focusedWindow()

  for _, bid in ipairs(apps.stack) do
    local app = hs.application.get(bid)
    if app then
      if app:isHidden() then app:unhide() end
      for _, win in ipairs(app:allWindows()) do
        if win:isStandard() and not win:isMinimized() then
          frame.placeWindow(win, rect)
        end
      end
    end
  end

  if focused then focused:focus() end
end

--- cmd+alt+R — everything one slot along. With two that is a swap; with three,
--- 1 2 3 becomes 3 1 2.
function M.rotate()
  local targets = M.current
  if #targets < 2 then return end
  table.insert(targets, 1, table.remove(targets))
  place()
end

--- cmd+` — the terminal, front and centre or out of the way.
function M.toggleTerminal()
  local app = hs.application.get(apps.bundles.terminal)
  if app and app:isFrontmost() then
    app:hide()
  else
    hs.application.launchOrFocusByBundleID(apps.bundles.terminal)
  end
end

return M
