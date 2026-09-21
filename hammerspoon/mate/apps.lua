local M = {}

M.bundles = {
	terminal = "org.alacritty",
	-- browser is what the layouts and cmd+alt+§ place; defaultBrowser is what
	-- opens a link. One app, two jobs, and they stay two keys.
	browser = "com.google.Chrome",
	defaultBrowser = "com.google.Chrome",
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
