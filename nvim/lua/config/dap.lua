local dap = require("dap")
local dap_utils = require("dap.utils")
local dapui = require("dapui")

-- Signs
vim.fn.sign_define("DapBreakpoint", { text = "B", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "C", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "L", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = ">", texthl = "", linehl = "DapStoppedLine", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "X", texthl = "", linehl = "", numhl = "" })
vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#45475a" })

-- Mason DAP
require("mason-nvim-dap").setup({
	ensure_installed = { "js-debug-adapter" },
	automatic_installation = true,
	handlers = {},
})

-- DAP UI
dapui.setup()
dap.listeners.after.event_initialized["dapui_config"] = dapui.open
dap.listeners.before.event_terminated["dapui_config"] = dapui.close
dap.listeners.before.event_exited["dapui_config"] = dapui.close

-- JS/TS debug adapter (mason)
local js_debug_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

dap.adapters["pwa-node"] = {
	type = "server",
	host = "localhost",
	port = "${port}",
	executable = {
		command = "node",
		args = { js_debug_path, "${port}" },
	},
}

-- Shared JS/TS launch templates
local node_base = {
	type = "pwa-node",
	request = "launch",
	program = "${file}",
	cwd = "${workspaceFolder}",
	console = "integratedTerminal",
	internalConsoleOptions = "neverOpen",
	resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
}

local node_launch = vim.tbl_deep_extend("force", node_base, { name = "Launch file" })
local node_launch_env = vim.tbl_deep_extend("force", node_base, { name = "Launch file (.env)", runtimeArgs = { "--env-file=.env" } })
local node_attach = {
	type = "pwa-node",
	request = "attach",
	name = "Attach",
	processId = dap_utils.pick_process,
	cwd = "${workspaceFolder}",
}

local ts_launch = vim.tbl_deep_extend("force", node_base, {
	name = "Launch TS file",
	skipFiles = { "<node_internals>/**" },
})
local ts_launch_env = vim.tbl_deep_extend("force", ts_launch, {
	name = "Launch TS file with .env",
	envFile = "${workspaceFolder}/.env",
})
local ts_launch_aws = vim.tbl_deep_extend("force", ts_launch, {
	name = "Launch TS file with AWS_PROFILE",
	envFile = "${workspaceFolder}/.env",
	env = function()
		local profile = vim.fn.input("AWS_PROFILE [personal]: ")
		if profile == "" then
			profile = "personal"
		end
		return { AWS_PROFILE = profile }
	end,
})

if vim.fn.executable("npx") == 1 then
	ts_launch.runtimeExecutable = "npx"
	ts_launch.runtimeArgs = { "tsx" }
	ts_launch_env.runtimeExecutable = "npx"
	ts_launch_env.runtimeArgs = { "tsx", "--env-file=.env" }
	ts_launch_aws.runtimeExecutable = "npx"
	ts_launch_aws.runtimeArgs = { "tsx", "--env-file=.env" }
end

dap.configurations.javascript = { vim.deepcopy(node_launch), vim.deepcopy(node_launch_env), vim.deepcopy(node_attach) }
dap.configurations.javascriptreact = { vim.deepcopy(node_launch), vim.deepcopy(node_launch_env), vim.deepcopy(node_attach) }
dap.configurations.typescript = { vim.deepcopy(ts_launch), vim.deepcopy(ts_launch_env), vim.deepcopy(ts_launch_aws), vim.deepcopy(node_attach) }
dap.configurations.typescriptreact = { vim.deepcopy(ts_launch), vim.deepcopy(ts_launch_env), vim.deepcopy(ts_launch_aws), vim.deepcopy(node_attach) }

-- Go (delve)
local dlv_cmd = vim.fn.executable("dlv") == 1 and "dlv" or vim.fn.stdpath("data") .. "/mason/bin/dlv"

dap.adapters.go = {
	type = "server",
	port = "${port}",
	executable = {
		command = dlv_cmd,
		args = { "dap", "-l", "127.0.0.1:${port}" },
	},
}

dap.configurations.go = {
	{ type = "go", name = "Debug", request = "launch", program = "${file}" },
	{ type = "go", name = "Debug (go.mod)", request = "launch", program = "${workspaceFolder}" },
	{ type = "go", name = "Debug test", request = "launch", mode = "test", program = "${file}" },
	{ type = "go", name = "Debug test (go.mod)", request = "launch", mode = "test", program = "${workspaceFolder}" },
	{ type = "go", name = "Attach remote", mode = "remote", request = "attach" },
}

-- Keymaps
vim.keymap.set("n", "<M-1>", dap.continue, { desc = "Debug: Continue" })
vim.keymap.set("n", "<M-2>", dap.step_over, { desc = "Debug: Step Over" })
vim.keymap.set("n", "<M-3>", dap.step_into, { desc = "Debug: Step Into" })
vim.keymap.set("n", "<M-4>", dap.step_out, { desc = "Debug: Step Out" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: Set Conditional Breakpoint" })
vim.keymap.set("n", "<leader>dc", dap.clear_breakpoints, { desc = "Debug: Clear Breakpoints" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Debug: Open REPL" })
vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Debug: Run Last" })
vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug: Terminate" })
vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: Toggle UI" })
