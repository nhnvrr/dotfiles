-- nvim-dap. nvim-nio is a hard requirement of dap-ui, not an optional extra.
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

require("nvim-dap-virtual-text").setup({
  -- eol and not inline: inline pushes the code sideways as values change, and
  -- the line stops matching the file you are reading.
  virt_text_pos = "eol",
  commented = true,
})

-- The UI opens and closes with the session rather than by hand. `before` on the
-- terminate/exit events, so it is still around to show the final frame.
dap.listeners.after.event_initialized["dapui"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui"] = function()
  dapui.close()
end

vim.fn.sign_define("DapBreakpoint", { text = "B", texthl = "DiagnosticError" })
vim.fn.sign_define("DapBreakpointCondition", { text = "C", texthl = "DiagnosticWarn" })
vim.fn.sign_define("DapLogPoint", { text = "L", texthl = "DiagnosticInfo" })
vim.fn.sign_define("DapStopped", { text = ">", texthl = "DiagnosticOk", linehl = "Visual" })
vim.fn.sign_define("DapBreakpointRejected", { text = "R", texthl = "DiagnosticHint" })

-- Go. dap-go finds dlv on PATH and registers "debug package", "debug test" and
-- "attach" by itself; there is nothing to configure.
require("dap-go").setup()

-- Rust is configured by rustaceanvim in lsp.lua, which wires its own
-- debuggables straight into this dap session — <leader>dR over a fn main or a
-- #[test] builds and launches with no launch.json anywhere.

-- Node and TypeScript. vscode-js-debug is neither a Homebrew formula nor an npm
-- package, so install.sh vendors the release tarball; this is the standalone
-- DAP server it ships. `${port}` makes dap pick a free one per session.
--
-- The third argument is the trap. dapDebugServer takes `[port] [host=localhost]`
-- and macOS resolves localhost to ::1, so the server binds IPv6-only while dap
-- dials 127.0.0.1 and gets ECONNREFUSED. Passing the address explicitly keeps
-- both ends on IPv4. The error nvim-dap prints for this reads
-- "Couldn't connect to 127.0.0.1:${port}" with the placeholder unexpanded —
-- that part is cosmetic, dap substitutes the real port on a copy of the adapter
-- and formats the message from the original table.
local js_debug = vim.fn.expand("~/.local/share/nvim/js-debug/src/dapDebugServer.js")

if vim.uv.fs_stat(js_debug) then
  dap.adapters["pwa-node"] = {
    type = "server",
    host = "127.0.0.1",
    port = "${port}",
    executable = {
      command = "node",
      args = { js_debug, "${port}", "127.0.0.1" },
    },
  }

  for _, filetype in ipairs({ "typescript", "typescriptreact", "javascript", "javascriptreact" }) do
    dap.configurations[filetype] = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch current file",
        program = "${file}",
        cwd = "${workspaceFolder}",
        -- tsx keeps TypeScript runnable without a build step; sourceMaps is
        -- what makes the breakpoints land on the .ts and not on the transpiled
        -- output.
        runtimeExecutable = "npx",
        runtimeArgs = { "tsx" },
        sourceMaps = true,
        protocol = "inspector",
        console = "integratedTerminal",
        skipFiles = { "<node_internals>/**", "**/node_modules/**" },
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach to process on :9229",
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        skipFiles = { "<node_internals>/**", "**/node_modules/**" },
      },
    }
  end
end

-- F-keys for the stepping, which is what gets pressed in a loop, and <leader>d
-- for everything else. That prefix used to be black-hole delete; it moved to
-- <leader>x in keymaps.lua, because leaving it here made every dap chord wait
-- out timeoutlen.
vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: continue / start" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: step over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: step into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: step out" })

vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue / start" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
  vim.ui.input({ prompt = "Breakpoint condition: " }, function(condition)
    if condition then
      dap.set_breakpoint(condition)
    end
  end)
end, { desc = "Conditional breakpoint" })
vim.keymap.set("n", "<leader>dl", function()
  vim.ui.input({ prompt = "Log message: " }, function(message)
    if message then
      dap.set_breakpoint(nil, nil, message)
    end
  end)
end, { desc = "Log point" })
vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "Toggle REPL" })
vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle debug UI" })
vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step out" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
vim.keymap.set("n", "<leader>dv", dap.step_over, { desc = "Step over" })
vim.keymap.set("n", "<leader>dR", function()
  -- rustaceanvim owns Rust debugging; everywhere else this restarts the session.
  if vim.bo.filetype == "rust" then
    vim.cmd.RustLsp("debuggables")
  else
    dap.restart()
  end
end, { desc = "Runnable / restart" })
vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate session" })
vim.keymap.set("n", "<leader>dx", dap.clear_breakpoints, { desc = "Clear all breakpoints" })

-- Evaluate the expression under the cursor, or the selection. "x" and not "v":
-- Select mode has to keep <leader> literal for snippet placeholders.
vim.keymap.set({ "n", "x" }, "<leader>de", function()
  require("dapui").eval(nil, { enter = true })
end, { desc = "Evaluate expression" })
