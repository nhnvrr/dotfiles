local M = {}

M.bundles = {
	terminal = "com.mitchellh.ghostty",
	browser = "com.google.Chrome",
	defaultBrowser = "com.google.Chrome",
	zed = "dev.zed.Zed",
	tableplus = "com.tinyapp.TablePlus",
	notes = "com.apple.Notes",
	docker = "com.electron.dockerdesktop",
}

M.stack = {
	M.bundles.terminal,
	M.bundles.browser,
	M.bundles.zed,
	M.bundles.tableplus,
	M.bundles.notes,
	M.bundles.docker,
}

return M
