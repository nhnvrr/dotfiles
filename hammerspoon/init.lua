-- Auto-reload on config change
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()
hs.alert.show("Hammerspoon loaded")

local gap = 2

local function layout(apps)
	local f = hs.screen.mainScreen():frame()

	for _, app in ipairs(apps) do
		if app.id then
			hs.application.launchOrFocusByBundleID(app.id)
		else
			hs.application.launchOrFocus(app.name)
		end
	end

	hs.timer.doAfter(0.5, function()
		for _, app in ipairs(apps) do
			local a = app.id and hs.application.get(app.id) or hs.application.find(app.name)
			if a and a:mainWindow() then
				a:mainWindow():setFrame(app.rect(f))
			end
		end
	end)
end

local function left(f, ratio)
	return hs.geometry.rect(f.x, f.y, f.w * ratio - gap, f.h)
end

local function right(f, ratio)
	local split = f.w * (1 - ratio)
	return hs.geometry.rect(f.x + split + gap, f.y, f.w * ratio - gap, f.h)
end

local function topLeft(f, wRatio, hRatio)
	return hs.geometry.rect(f.x, f.y, f.w * wRatio - gap, f.h * hRatio - gap)
end

local function bottomLeft(f, wRatio, hRatio)
	return hs.geometry.rect(f.x, f.y + f.h * (1 - hRatio) + gap, f.w * wRatio - gap, f.h * hRatio - gap)
end

local function full(f)
	return hs.geometry.rect(f.x, f.y, f.w, f.h)
end

local safari = "com.apple.Safari"
local chrome = "com.google.Chrome"
local vscode = "com.microsoft.VSCode"
local terminal = "com.apple.Terminal"
local postico = "at.eggerapps.Postico"
local slack = "com.tinyspeck.slackmacgap"
local personalBrowser = "Dia"

-- Cmd+Option+1: Gather left 2/9, Chrome right 7/9
hs.hotkey.bind({ "cmd", "alt" }, "1", function()
	layout({
		{ name = "Gather", rect = function(f) return left(f, 2/9) end },
		{ id = chrome, rect = function(f) return right(f, 7/9) end },
	})
end)

-- Cmd+Option+2: Terminal left 1/3, Chrome right 2/3
hs.hotkey.bind({ "cmd", "alt" }, "2", function()
	layout({
		{ id = terminal, rect = function(f) return left(f, 1/3) end },
		{ id = chrome, rect = function(f) return right(f, 2/3) end },
	})
end)

-- Cmd+Option+3: Terminal left 2/7, Postico 2 right 5/7
hs.hotkey.bind({ "cmd", "alt" }, "3", function()
	layout({
		{ id = terminal, rect = function(f) return left(f, 2/7) end },
		{ id = postico, rect = function(f) return right(f, 5/7) end },
	})
end)

-- Cmd+Option+9: Dia left 5/7, Terminal right 2/7
hs.hotkey.bind({ "cmd", "alt" }, "9", function()
	layout({
		{ id = terminal, rect = function(f) return right(f, 2/7) end },
		{ name = personalBrowser, rect = function(f) return left(f, 5/7) end },
	})
end)

-- Cmd+Option+0: Terminal left 5/7, Dia right 2/7
hs.hotkey.bind({ "cmd", "alt" }, "0", function()
	layout({
		{ name = personalBrowser, rect = function(f) return right(f, 2/7) end },
		{ id = terminal, rect = function(f) return left(f, 5/7) end },
	})
end)

-- Cmd+Option+-: VS Code left 5/7, Dia right 2/7
hs.hotkey.bind({ "cmd", "alt" }, "-", function()
	layout({
		{ name = personalBrowser, rect = function(f) return right(f, 2/7) end },
		{ id = vscode, rect = function(f) return left(f, 5/7) end },
	})
end)
