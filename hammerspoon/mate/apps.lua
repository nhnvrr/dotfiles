local M = {}

M.bundles = {
	terminal = "org.alacritty",
	-- browser is what the layouts and cmd+alt+§ place; defaultBrowser is what
	-- opens a link. Same app today, separate jobs -- Chrome stays installed for
	-- work and is opened by hand.
	browser = "com.apple.Safari",
	defaultBrowser = "com.apple.Safari",
	-- The work browser, placed only by cmd+alt+4.
	chrome = "com.google.Chrome",
	vscode = "com.microsoft.VSCode",
	datagrip = "com.jetbrains.datagrip",
	notes = "com.apple.Notes",
	-- The window belongs to the Electron shell, not to com.docker.docker,
	-- which owns the daemon and has no window at all.
	docker = "com.electron.dockerdesktop",
}

-- What cmd+alt+§ stacks. Declared, not "whatever is running".
M.stack = {
	M.bundles.terminal,
	M.bundles.browser,
	M.bundles.vscode,
	M.bundles.datagrip,
	M.bundles.notes,
	M.bundles.docker,
}

return M
