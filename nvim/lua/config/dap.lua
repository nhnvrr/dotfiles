local dap = require("dap")
local dapui = require("dapui")

require("mason-nvim-dap").setup({
  ensure_installed = { "js-debug-adapter" },
  automatic_installation = true,
  handlers = {
    function(config)
      require("mason-nvim-dap").default_setup(config)
    end,
  },
})

require("nvim-dap-virtual-text").setup({
  commented = true,
})

dapui.setup()

-- Auto open/close UI when a session starts or ends.
dap.listeners.before.attach.dapui_config = function() dapui.open() end
dap.listeners.before.launch.dapui_config = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

-- pwa-node adapter (vscode-js-debug installed via Mason).
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

-- Default launch configurations for JS/TS. nvim-dap reads .vscode/launch.json
-- automatically on-demand for any filetype with configured adapters.
for _, lang in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
  dap.configurations[lang] = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch current file (node)",
      program = "${file}",
      cwd = "${workspaceFolder}",
      runtimeExecutable = "node",
      skipFiles = { "<node_internals>/**" },
      sourceMaps = true,
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch current file (tsx)",
      program = "${file}",
      cwd = "${workspaceFolder}",
      runtimeExecutable = "tsx",
      skipFiles = { "<node_internals>/**" },
      sourceMaps = true,
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch current file with .env (tsx)",
      program = "${file}",
      cwd = "${workspaceFolder}",
      runtimeExecutable = "tsx",
      envFile = "${workspaceFolder}/.env",
      skipFiles = { "<node_internals>/**" },
      sourceMaps = true,
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach to running Node process",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
      sourceMaps = true,
    },
  }
end
