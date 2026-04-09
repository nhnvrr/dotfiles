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

local brave = "com.brave.Browser"
local chrome = "com.google.Chrome"
local vscode = "com.microsoft.VSCode"
local terminal = "com.apple.Terminal"
local slack = "com.tinyspeck.slackmacgap"

-- Cmd+Option+0: Brave left 2/7, VSCode right 5/7
hs.hotkey.bind({ "cmd", "alt" }, "0", function()
	layout({
		{ id = brave, rect = function(f) return left(f, 2/7) end },
		{ id = vscode, rect = function(f) return right(f, 5/7) end },
	})
end)

-- Cmd+Option+1: Chrome right 4/7, Slack top-left 3/7, Gather bottom-left 3/7
hs.hotkey.bind({ "cmd", "alt" }, "1", function()
	layout({
		{ id = chrome, rect = function(f) return right(f, 4/7) end },
		{ id = slack, rect = function(f) return topLeft(f, 3/7, 1/2) end },
		{ name = "Gather", rect = function(f) return bottomLeft(f, 3/7, 1/2) end },
	})
end)

-- Cmd+Option+2: Gather left 1/4, Chrome right 3/4
hs.hotkey.bind({ "cmd", "alt" }, "2", function()
	layout({
		{ name = "Gather", rect = function(f) return left(f, 1/4) end },
		{ id = chrome, rect = function(f) return right(f, 3/4) end },
	})
end)

-- Cmd+Option+3: Terminal left 1/3, Brave right 2/3
hs.hotkey.bind({ "cmd", "alt" }, "3", function()
	layout({
		{ id = terminal, rect = function(f) return left(f, 1/3) end },
		{ id = brave, rect = function(f) return right(f, 2/3) end },
	})
end)

-- Cmd+Option+4: Brave left 2/7, Terminal right 5/7
hs.hotkey.bind({ "cmd", "alt" }, "4", function()
	layout({
		{ id = brave, rect = function(f) return left(f, 2/7) end },
		{ id = terminal, rect = function(f) return right(f, 5/7) end },
	})
end)

-- Cmd+Option+9: Terminal maximized
hs.hotkey.bind({ "cmd", "alt" }, "9", function()
	layout({
		{ id = terminal, rect = full },
	})
end)
