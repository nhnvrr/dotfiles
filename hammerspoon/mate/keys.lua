--- The whole keymap, in one file.
---
--- Keys split by modifier: Alacritty takes cmd, Hammerspoon takes cmd+alt for
--- the workspace and the display, ctrl+alt for the i3-style bindings, zsh
--- takes bare ctrl, and tmux takes ctrl+b as its prefix.
---
--- ctrl+alt and not bare alt: alacritty.toml sets option_as_alt = "Both" so
--- option+b and option+f word-jump in the shell, and a hotkey here is global —
--- it takes the key before the terminal ever sees it. cmd+alt is taken by the
--- workspace bindings.
---
--- This is not a tiling window manager and does not pretend to be one: there is
--- no tree, so nothing reflows when a window opens or closes and two windows can
--- overlap if you put them there. What it buys is the part of i3 that gets used
--- all day — moving focus and slotting a window into a half without the mouse.

local motion    = require("mate.motion")
local screen    = require("mate.screen")
local workspace = require("mate.workspace")

local M = {}

--- Every hotkey object lives here for the life of the config, for the same
--- reason the watchers do: nothing else holds a reference to them.
M.hotkeys = {}

local function bind(mods, key, fn)
  M.hotkeys[#M.hotkeys + 1] = hs.hotkey.bind(mods, key, fn)
end

-- ─── cmd+alt: the workspace and the display ─────────────────────────────────

bind({ "cmd", "alt" }, "1", workspace.layout)
bind({ "cmd", "alt" }, "2", workspace.code)
bind({ "cmd", "alt" }, "3", workspace.development)
bind({ "cmd", "alt" }, "R", workspace.rotate)
bind({ "cmd", "alt" }, "0", screen.toggleResolution)
bind({ "cmd", "alt" }, "F", motion.toggleZoom)
-- Keycode 10, the ISO key left of 1. Absent from an ANSI keyboard.
bind({ "cmd", "alt" }, "§", workspace.zoomAll)
bind({ "cmd", "alt", "ctrl" }, "R", hs.reload)

bind({ "cmd" }, "`", workspace.toggleTerminal)

-- ─── ctrl+alt: the i3-style set ─────────────────────────────────────────────

for key in pairs(motion.directions) do
  bind({ "ctrl", "alt" }, key, function() motion.focus(key) end)
  bind({ "ctrl", "alt", "shift" }, key, function() motion.half(key) end)
end

bind({ "ctrl", "alt" }, "-", function() motion.resizeWidth(-80) end)
bind({ "ctrl", "alt" }, "=", function() motion.resizeWidth(80) end)
bind({ "ctrl", "alt" }, "c", motion.centre)

-- The two halves again, on a home-row-adjacent pair. Same motion.half as
-- ctrl+alt+shift+h/l, which stay bound.
bind({ "cmd", "alt" }, "z", function() motion.half("h") end)
bind({ "cmd", "alt" }, "x", function() motion.half("l") end)

-- Centre on the same modifier as the halves, so the three placements a window
-- actually gets sit together. ctrl+alt+c stays bound to the same function.
--
-- This takes cmd+alt+c globally, and Finder spends it on "Copy as Pathname" —
-- the Option variant of cmd+c. A hotkey here wins, so that stops working.
bind({ "cmd", "alt" }, "c", motion.centre)

bind({ "ctrl", "alt" }, ",", function() screen.moveToScreen(-1) end)
bind({ "ctrl", "alt" }, ".", function() screen.moveToScreen(1) end)

return M
