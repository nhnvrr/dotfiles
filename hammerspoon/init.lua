-- Auto-reload on config change
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()
hs.alert.show("Hammerspoon loaded")

local gap = 2

-- Cmd+Option+0: Chrome left 2/7, VSCode right 5/7, full height
hs.hotkey.bind({ "cmd", "alt" }, "0", function()
	local screen = hs.screen.mainScreen()
	local f = screen:frame()

	hs.application.launchOrFocusByBundleID("com.microsoft.VSCode")
	hs.application.launchOrFocusByBundleID("com.google.Chrome")

	hs.timer.doAfter(0.5, function()
		local vscode = hs.application.get("com.microsoft.VSCode")
		local chrome = hs.application.get("com.google.Chrome")
		local split = f.w * 2 / 7

		if chrome and chrome:mainWindow() then
			chrome:mainWindow():setFrame(hs.geometry.rect(f.x, f.y, split - gap, f.h))
		end
		if vscode and vscode:mainWindow() then
			vscode:mainWindow():setFrame(hs.geometry.rect(f.x + split + gap, f.y, f.w - split - gap, f.h))
		end
	end)
end)

-- Cmd+Option+1: Chrome right 2/3, Slack top-left 1/3, Gather bottom-left 1/3
hs.hotkey.bind({ "cmd", "alt" }, "1", function()
	local screen = hs.screen.mainScreen()
	local f = screen:frame()

	hs.application.launchOrFocusByBundleID("com.google.Chrome")
	hs.application.launchOrFocusByBundleID("com.tinyspeck.slackmacgap")
	hs.application.launchOrFocus("Gather")

	hs.timer.doAfter(0.5, function()
		local chrome = hs.application.get("com.google.Chrome")
		local slack = hs.application.get("com.tinyspeck.slackmacgap")
		local gather = hs.application.find("Gather")

		local split = f.w * 3 / 7

		if chrome and chrome:mainWindow() then
			chrome:mainWindow():setFrame(hs.geometry.rect(f.x + split + gap, f.y, f.w - split - gap, f.h))
		end
		if slack and slack:mainWindow() then
			slack:mainWindow():setFrame(hs.geometry.rect(f.x, f.y, split - gap, f.h / 2 - gap))
		end
		if gather and gather:mainWindow() then
			gather:mainWindow():setFrame(hs.geometry.rect(f.x, f.y + f.h / 2 + gap, split - gap, f.h / 2 - gap))
		end
	end)
end)

-- Cmd+Option+2: Gather left 1/4, Chrome right 3/4, full height
hs.hotkey.bind({ "cmd", "alt" }, "2", function()
	local screen = hs.screen.mainScreen()
	local f = screen:frame()

	hs.application.launchOrFocusByBundleID("com.google.Chrome")
	hs.application.launchOrFocus("Gather")

	hs.timer.doAfter(0.5, function()
		local chrome = hs.application.get("com.google.Chrome")
		local gather = hs.application.find("Gather")

		local split = f.w / 4

		if gather and gather:mainWindow() then
			gather:mainWindow():setFrame(hs.geometry.rect(f.x, f.y, split - gap, f.h))
		end
		if chrome and chrome:mainWindow() then
			chrome:mainWindow():setFrame(hs.geometry.rect(f.x + split + gap, f.y, f.w - split - gap, f.h))
		end
	end)
end)

-- Cmd+Option+3: Alacritty left 1/3, Chrome right 2/3, full height
hs.hotkey.bind({ "cmd", "alt" }, "3", function()
	local screen = hs.screen.mainScreen()
	local f = screen:frame()

	hs.application.launchOrFocusByBundleID("com.google.Chrome")
	hs.application.launchOrFocusByBundleID("org.alacritty")

	hs.timer.doAfter(0.5, function()
		local chrome = hs.application.get("com.google.Chrome")
		local terminal = hs.application.get("org.alacritty")

		local split = f.w / 3

		if terminal and terminal:mainWindow() then
			terminal:mainWindow():setFrame(hs.geometry.rect(f.x, f.y, split - gap, f.h))
		end
		if chrome and chrome:mainWindow() then
			chrome:mainWindow():setFrame(hs.geometry.rect(f.x + split + gap, f.y, f.w - split - gap, f.h))
		end
	end)
end)

-- Cmd+Option+4: Chrome left 2/7, Alacritty right 5/7, full height
hs.hotkey.bind({ "cmd", "alt" }, "4", function()
	local screen = hs.screen.mainScreen()
	local f = screen:frame()

	hs.application.launchOrFocusByBundleID("com.google.Chrome")
	hs.application.launchOrFocusByBundleID("org.alacritty")

	hs.timer.doAfter(0.5, function()
		local chrome = hs.application.get("com.google.Chrome")
		local terminal = hs.application.get("org.alacritty")
		local split = f.w * 2 / 7

		if chrome and chrome:mainWindow() then
			chrome:mainWindow():setFrame(hs.geometry.rect(f.x, f.y, split - gap, f.h))
		end
		if terminal and terminal:mainWindow() then
			terminal:mainWindow():setFrame(hs.geometry.rect(f.x + split + gap, f.y, f.w - split - gap, f.h))
		end
	end)
end)

-- Cmd+Option+9: Alacritty maximized
hs.hotkey.bind({ "cmd", "alt" }, "9", function()
	local screen = hs.screen.mainScreen()
	local f = screen:frame()

	hs.application.launchOrFocusByBundleID("org.alacritty")

	hs.timer.doAfter(0.5, function()
		local terminal = hs.application.get("org.alacritty")
		if terminal and terminal:mainWindow() then
			terminal:mainWindow():setFrame(hs.geometry.rect(f.x, f.y, f.w, f.h))
		end
	end)
end)
