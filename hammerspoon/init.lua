--- Window layout for a single-screen macOS desktop: a two-app workspace on
--- cmd+alt, an i3-style set of motions on ctrl+alt, and a focus ring.
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

require("mate.workspace")
require("mate.autozoom") -- every new window opens at full screen
require("mate.border")
require("mate.appearance")
require("mate.keys")

-- Reasserted on every load rather than left to install.sh: LaunchServices drops
-- duti's call for http/https often enough, and any browser that runs can offer
-- to take the handler back. So cmd+alt+ctrl+R is the fix for a stolen default.
require("mate.browser").ensureDefault()

hs.alert.show("Hammerspoon loaded")
