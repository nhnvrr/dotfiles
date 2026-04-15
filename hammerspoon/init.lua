local config = {
	appModifiers = { "cmd", "alt" },
	reloadModifiers = { "cmd", "alt", "ctrl" },
	reloadKey = "R",
}

local shortcuts = {
	{ key = "1", name = "Terminal", id = "com.apple.Terminal" },
	{ key = "2", name = "Google Chrome", id = "com.google.Chrome" },
	{ key = "3", name = "Visual Studio Code", id = "com.microsoft.VSCode" },
	{ key = "4", name = "Postico", id = "at.eggerapps.Postico" },
	{ key = "5", name = "Postman", id = "com.postmanlabs.mac" },
	{ key = "9", name = "Brave Browser", id = "com.brave.Browser" },
	{ key = "0", name = "Linear" },
}

local function launchOrFocus(app)
	if app.id and hs.application.launchOrFocusByBundleID(app.id) then
		return
	end

	hs.application.launchOrFocus(app.name)
end

local reloadWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload)
reloadWatcher:start()

for _, shortcut in ipairs(shortcuts) do
	hs.hotkey.bind(config.appModifiers, shortcut.key, function()
		launchOrFocus(shortcut)
	end)
end

hs.hotkey.bind(config.reloadModifiers, config.reloadKey, hs.reload)
hs.alert.show("Hammerspoon loaded")
