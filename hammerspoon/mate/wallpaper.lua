--- The desktop picture follows the macOS appearance: wallpaper-dark.jpg in
--- Dark, wallpaper-light.jpg in Light. install.sh copies both to ~/Pictures and
--- sets the first one; this keeps it right after every switch.

local M = {}

local DIR = os.getenv("HOME") .. "/Pictures/"

local function apply()
	local style = hs.host.interfaceStyle() == "Dark" and "dark" or "light"
	local url = "file://" .. DIR .. "wallpaper-" .. style .. ".jpg"
	for _, screen in ipairs(hs.screen.allScreens()) do
		screen:desktopImageURL(url)
	end
end

-- Held on the module or Hammerspoon collects it and the switch stops firing.
M.watcher = hs.distributednotifications.new(apply, "AppleInterfaceThemeChangedNotification")
M.watcher:start()

apply()

return M
