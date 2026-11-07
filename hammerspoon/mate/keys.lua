--- The whole keymap, in one file. Three window keys on cmd+alt: Ghostty takes
--- cmd, the shell takes bare ctrl, and bare alt is option+b / option+f in the
--- shell because Ghostty sets macos-option-as-alt. A hotkey here is global — it
--- takes the key before the terminal ever sees it.

local motion = require("mate.motion")

local M = {}

--- Every hotkey object lives here for the life of the config: nothing else
--- holds a reference to them.
M.hotkeys = {}

local function bind(key, fn)
  M.hotkeys[#M.hotkeys + 1] = hs.hotkey.bind({ "cmd", "alt" }, key, fn)
end

bind("0", motion.zoomAll)
bind("-", function() motion.pane("h") end)
bind("=", function() motion.pane("l") end)

-- cmd+§ also cycles the app's windows. The system shortcut (Move focus to next
-- window) holds a single combo, so this replays the one it has: cmd + keycode
-- 50. A keycode, not "`": on ISO layouts macOS can swap the § and ` keys.
M.hotkeys[#M.hotkeys + 1] = hs.hotkey.bind({ "cmd" }, "§", function()
  hs.eventtap.keyStroke({ "cmd" }, 50, 0)
end)

return M
