-- mason, dap, dapui and nio are ~12ms together, and nvim is $EDITOR: every
-- `git commit` used to pay them to render a commit message. Nothing below runs
-- until the first debug key.
local loaded = false

local function load()
  if loaded then
    return
  end
  loaded = true

  require("mason").setup()

  -- mason has no declarative "ensure installed" of its own. This is its registry
  -- API, run async so a cold checkout never blocks on two downloads.
  do
    local names = { "js-debug-adapter", "codelldb" }
    local ok, registry = pcall(require, "mason-registry")
    if ok then
      registry.refresh(function()
        for _, name in ipairs(names) do
          local found, pkg = pcall(registry.get_package, name)
          if found and not pkg:is_installed() then
            pkg:install()
          end
        end
      end)
    end
  end

  local dap = require("dap")
  local dapui = require("dapui")

  dapui.setup()
  require("nvim-dap-virtual-text").setup({ virt_text_pos = "eol" })

  -- dlv comes from the Brewfile, so Go needs no adapter wiring beyond this.
  require("dap-go").setup()

  -- Rust is not configured here on purpose: rustaceanvim discovers codelldb in
  -- mason's install path and registers the adapter itself. `:RustLsp debuggables`
  -- is the entry point, not dap.continue().

  local js_debug = vim.fn.stdpath("data")
    .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

  dap.adapters["pwa-node"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "node",
      -- ${port} is substituted by nvim-dap, not by the shell.
      args = { js_debug, "${port}" },
    },
  }

  for _, ft in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
    dap.configurations[ft] = {
      {
        type = "pwa-node",
        request = "launch",
        -- Node 24 strips TypeScript types natively, so a .ts entrypoint runs
        -- without tsx or ts-node in front of it. On an older Node this needs a
        -- runtimeExecutable that can.
        name = "Launch current file",
        program = "${file}",
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        skipFiles = { "<node_internals>/**", "**/node_modules/**" },
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach to a running process",
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        skipFiles = { "<node_internals>/**", "**/node_modules/**" },
      },
    }
  end

  -- Safe to register after load(): event_initialized cannot arrive until the
  -- adapter answers over the socket, many ms and a different tick from here.
  for _, event in ipairs({ "launch", "attach" }) do
    dap.listeners.after.event_initialized["dapui_" .. event] = function() dapui.open() end
  end
  dap.listeners.before.event_terminated.dapui = function() dapui.close() end
  dap.listeners.before.event_exited.dapui = function() dapui.close() end
end

-- The first press has to do the thing, not just load the subsystem.
local function on_demand(action)
  return function()
    load()
    return action(require("dap"), require("dapui"))
  end
end

-- rustaceanvim resolves codelldb through mason-registry, and get_package only
-- sees anything once mason.setup() has appended its registry sources; it then
-- expands $MASON, which the same setup() is what sets. Without this,
-- `:RustLsp debuggables` ends up with no adapter and only a notify.
vim.api.nvim_create_autocmd("FileType", { pattern = "rust", once = true, callback = load })

-- Keep the stepping controls together on one adjacent Ctrl row.
vim.keymap.set("n", "<C-8>", on_demand(function(dap) return dap.continue() end),
  { desc = "Debug: continue / start" })
vim.keymap.set("n", "<C-9>", on_demand(function(dap) return dap.step_over() end),
  { desc = "Debug: step over" })
vim.keymap.set("n", "<C-0>", on_demand(function(dap) return dap.step_into() end),
  { desc = "Debug: step into" })
vim.keymap.set("n", "<C-S-0>", on_demand(function(dap) return dap.step_out() end),
  { desc = "Debug: step out" })

vim.keymap.set("n", "<leader>db", on_demand(function(dap) return dap.toggle_breakpoint() end),
  { desc = "Debug: toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", on_demand(function(dap)
  return dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end), { desc = "Debug: conditional breakpoint" })
vim.keymap.set("n", "<leader>dr", on_demand(function(dap) return dap.repl.toggle() end),
  { desc = "Debug: REPL" })
vim.keymap.set("n", "<leader>dl", on_demand(function(dap) return dap.run_last() end),
  { desc = "Debug: re-run last" })
vim.keymap.set("n", "<leader>dt", on_demand(function(dap) return dap.terminate() end),
  { desc = "Debug: terminate" })
vim.keymap.set("n", "<leader>du", on_demand(function(_, dapui) return dapui.toggle() end),
  { desc = "Debug: toggle UI" })
vim.keymap.set({ "n", "v" }, "<leader>de", on_demand(function(_, dapui)
  return dapui.eval(nil, { enter = true })
end), { desc = "Debug: evaluate expression" })
