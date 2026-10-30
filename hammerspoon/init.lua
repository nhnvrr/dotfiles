--- Three window keys on cmd+alt: 0 puts every window at full screen, - and =
--- drop the focused one in the left or right pane. New windows open at full
--- screen on their own.
---
--- Everything lives in ./mate; this file only wires it up. The keymap is
--- mate/keys.lua and nothing else binds a key.

-- The slide between two frames. 0 snaps. frame.lua waits this out before it
-- verifies a placement, so this is the only number to change.
hs.window.animationDuration = 0.12

require("hs.ipc")
if hs.ipc and hs.ipc.cliInstall then
	hs.ipc.cliInstall()
end

-- Without Accessibility every placement in here silently no-ops, which is the
-- only reason this alert exists: there is no other symptom.
if not hs.accessibilityState(true) then
	hs.alert.show(
		"⚠️  Hammerspoon needs Accessibility.\n"
			.. "Settings → Privacy & Security → Accessibility → Hammerspoon ON",
		{ textSize = 18 },
		8
	)
end

require("mate.keys")
require("mate.spawn") -- every new window opens at full size

hs.alert.show("Hammerspoon loaded")
