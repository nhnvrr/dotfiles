vim.pack.add({
  "https://github.com/mfussenegger/nvim-dap",
  "https://github.com/rcarriga/nvim-dap-ui",
  "https://github.com/nvim-neotest/nvim-nio",
  "https://github.com/theHamsta/nvim-dap-virtual-text",
  "https://github.com/leoluz/nvim-dap-go",
})

local dap = require("dap")
local dapui = require("dapui")

dapui.setup({
  layouts = {
    {
      elements = {
        { id = "scopes", size = 0.35 },
        { id = "breakpoints", size = 0.15 },
        { id = "stacks", size = 0.25 },
        { id = "watches", size = 0.25 },
      },
      size = 44,
      position = "left",
    },
    {
      elements = { { id = "repl", size = 0.5 }, { id = "console", size = 0.5 } },
      size = 10,
      position = "bottom",
    },
  },
})
require("nvim-dap-virtual-text").setup({ virt_text_pos = "eol", commented = true })

dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui"] = function() dapui.close() end

vim.fn.sign_define("DapBreakpoint", { text = "B", texthl = "DiagnosticError" })
vim.fn.sign_define("DapBreakpointCondition", { text = "C", texthl = "DiagnosticWarn" })
vim.fn.sign_define("DapLogPoint", { text = "L", texthl = "DiagnosticInfo" })
vim.fn.sign_define("DapStopped", { text = ">", texthl = "DiagnosticOk", linehl = "Visual" })

require("dap-go").setup()

local lldb = vim.fn.exepath("lldb-dap")
if lldb == "" then
  local probe = vim.system({ "xcrun", "-f", "lldb-dap" }, { text = true }):wait()
  lldb = probe.code == 0 and vim.trim(probe.stdout) or ""
end
if lldb ~= "" then
  dap.adapters.lldb = { type = "executable", command = lldb, name = "lldb" }
  dap.configurations.rust = {
    {
      name = "Launch binary",
      type = "lldb",
      request = "launch",
      program = function()
        return vim.fn.input("Binary: ", vim.uv.cwd() .. "/target/debug/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
    },
  }
end

local js_debug = vim.fn.expand("~/.local/share/nvim/js-debug/src/dapDebugServer.js")
if vim.uv.fs_stat(js_debug) then
  dap.adapters["pwa-node"] = {
    type = "server",
    host = "127.0.0.1",
    port = "${port}",
    executable = { command = "node", args = { js_debug, "${port}", "127.0.0.1" } },
  }
  for _, ft in ipairs({ "typescript", "typescriptreact", "javascript", "javascriptreact" }) do
    dap.configurations[ft] = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch current file",
        program = "${file}",
        cwd = "${workspaceFolder}",
        runtimeExecutable = "npx",
        runtimeArgs = { "tsx" },
        sourceMaps = true,
        skipFiles = { "<node_internals>/**", "**/node_modules/**" },
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach to :9229",
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        skipFiles = { "<node_internals>/**", "**/node_modules/**" },
      },
    }
  end
end

local map = vim.keymap.set
map("n", "<F5>", dap.continue, { desc = "Continue" })
map("n", "<F10>", dap.step_over, { desc = "Step over" })
map("n", "<F11>", dap.step_into, { desc = "Step into" })
map("n", "<F12>", dap.step_out, { desc = "Step out" })
map("n", "<leader>dc", dap.continue, { desc = "Continue" })
map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Breakpoint" })
map("n", "<leader>dB", function()
  vim.ui.input({ prompt = "Condition: " }, function(c) if c then dap.set_breakpoint(c) end end)
end, { desc = "Conditional breakpoint" })
map("n", "<leader>dl", function()
  vim.ui.input({ prompt = "Log: " }, function(m) if m then dap.set_breakpoint(nil, nil, m) end end)
end, { desc = "Log point" })
map("n", "<leader>dv", dap.step_over, { desc = "Step over" })
map("n", "<leader>di", dap.step_into, { desc = "Step into" })
map("n", "<leader>do", dap.step_out, { desc = "Step out" })
map("n", "<leader>dr", dap.repl.toggle, { desc = "REPL" })
map("n", "<leader>du", dapui.toggle, { desc = "UI" })
map("n", "<leader>dR", dap.restart, { desc = "Restart" })
map("n", "<leader>dt", dap.terminate, { desc = "Terminate" })
map("n", "<leader>dx", dap.clear_breakpoints, { desc = "Clear breakpoints" })
map({ "n", "x" }, "<leader>de", function() dapui.eval(nil, { enter = true }) end, { desc = "Evaluate" })
