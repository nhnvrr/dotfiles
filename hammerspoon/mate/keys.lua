--- The whole keymap, in one file. Three keys, all on cmd+alt: Ghostty takes
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

return M
