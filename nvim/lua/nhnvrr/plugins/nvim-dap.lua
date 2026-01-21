return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "williamboman/mason.nvim",
    "jay-babu/mason-nvim-dap.nvim",
  },
  config = function()
    local dap = require("dap")
    local dap_utils = require("dap.utils")
    local mason_registry = require("mason-registry")

    -- Set up signs
    vim.fn.sign_define("DapBreakpoint", { text = "B", texthl = "", linehl = "", numhl = "" })
    vim.fn.sign_define("DapBreakpointCondition", { text = "C", texthl = "", linehl = "", numhl = "" })
    vim.fn.sign_define("DapLogPoint", { text = "L", texthl = "", linehl = "", numhl = "" })
    vim.fn.sign_define("DapStopped", { text = ">", texthl = "", linehl = "DapStoppedLine", numhl = "" })
    vim.fn.sign_define("DapBreakpointRejected", { text = "X", texthl = "", linehl = "", numhl = "" })

    -- Set up highlights
    vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#45475a" })

    -- Setup mason-nvim-dap
    require("mason-nvim-dap").setup({
      ensure_installed = { "js-debug-adapter" },
      automatic_installation = true,
      handlers = {},
    })

    local function get_js_debug_path()
      local candidates = {
        -- Local build (preferred when available)
        vim.fn.expand("~/src/vscode-js-debug/js-debug/src/dapDebugServer.js"),
      }

      for _, path in ipairs(candidates) do
        if vim.loop.fs_stat(path) then
          return path
        end
      end

      if mason_registry.has_package("js-debug-adapter") then
        local pkg = mason_registry.get_package("js-debug-adapter")
        if pkg and pkg.get_install_path then
          if not pkg:is_installed() then
            pkg:install()
          end
          local install_path = pkg:get_install_path()
          if install_path then
            return install_path .. "/js-debug/src/dapDebugServer.js"
          end
        end
      end

      -- Final fallback to the default Mason path even if not installed yet
      return vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
    end

    local js_debug_path = get_js_debug_path()
    local has_js_debug = js_debug_path and vim.loop.fs_stat(js_debug_path)
    if not has_js_debug then
      vim.notify(
        "js-debug no está en ~/src ni en Nix; usando ruta de Mason. Ejecuta :MasonInstall js-debug-adapter o compílalo en ~/src/vscode-js-debug.",
        vim.log.levels.WARN
      )
    end

    local function get_dlv_cmd()
      if vim.fn.executable("dlv") == 1 then
        return "dlv"
      end

      local mason_dlv = vim.fn.stdpath("data") .. "/mason/bin/dlv"
      if vim.loop.fs_stat(mason_dlv) then
        return mason_dlv
      end

      vim.notify("dlv no está instalado. Instálalo con Nix (pkgs.delve) o con :MasonInstall delve.", vim.log.levels
      .ERROR)
    end

    -- JavaScript Debug Adapter
    if js_debug_path then
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = { js_debug_path, "${port}" },
        },
      }
    else
      vim.notify("No se pudo determinar la ruta de js-debug; revisa get_js_debug_path()", vim.log.levels.ERROR)
    end

    -- Shared launch templates
    local node_base = {
      type = "pwa-node",
      request = "launch",
      program = "${file}",
      cwd = "${workspaceFolder}",
      console = "integratedTerminal",
      internalConsoleOptions = "neverOpen",
      resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
    }

    local node_launch = vim.tbl_deep_extend("force", node_base, {
      name = "Launch file",
    })

    local node_launch_env = vim.tbl_deep_extend("force", node_base, {
      name = "Launch file (.env)",
      runtimeArgs = { "--env-file=.env" },
    })

    local node_attach = {
      type = "pwa-node",
      request = "attach",
      name = "Attach",
      processId = dap_utils.pick_process,
      cwd = "${workspaceFolder}",
    }

    local ts_runtime_executable = "npx"
    if vim.fn.executable(ts_runtime_executable) == 0 then
      vim.notify("npx no está en el PATH; usa ts-node/tsx global o local para debuggear TS.", vim.log.levels.WARN)
      ts_runtime_executable = nil
    end

    local ts_launch = vim.tbl_deep_extend("force", node_base, {
      name = "Launch TS file (tsx)",
      skipFiles = { "<node_internals>/**" },
    })
    local ts_launch_env = vim.tbl_deep_extend("force", ts_launch, {
      name = "Launch TS file (tsx) with .env",
    })

    if ts_runtime_executable then
      ts_launch.runtimeExecutable = ts_runtime_executable
      ts_launch.runtimeArgs = { "tsx" }
      ts_launch_env.runtimeExecutable = ts_runtime_executable
      ts_launch_env.runtimeArgs = { "tsx", "--env-file=.env" }
    end

    local function clone(tbl)
      return vim.deepcopy(tbl)
    end

    -- Node.js debugging configuration
    dap.configurations.javascript = { clone(node_launch), clone(node_launch_env), clone(node_attach) }
    dap.configurations.javascriptreact = { clone(node_launch), clone(node_launch_env), clone(node_attach) }

    -- TypeScript debugging configurations
    dap.configurations.typescript = { clone(ts_launch), clone(ts_launch_env), clone(node_attach) }
    dap.configurations.typescriptreact = { clone(ts_launch), clone(ts_launch_env), clone(node_attach) }

    -- Go Debug Adapter
    local dlv_cmd = get_dlv_cmd()
    if dlv_cmd then
      dap.adapters.go = {
        type = "server",
        port = "${port}",
        executable = {
          command = dlv_cmd,
          args = { "dap", "-l", "127.0.0.1:${port}" },
        },
      }

      -- Go debugging configurations
      dap.configurations.go = {
        {
          type = "go",
          name = "Debug",
          request = "launch",
          program = "${file}",
        },
        {
          type = "go",
          name = "Debug (go.mod)",
          request = "launch",
          program = "${workspaceFolder}",
        },
        {
          type = "go",
          name = "Debug test",
          request = "launch",
          mode = "test",
          program = "${file}",
        },
        {
          type = "go",
          name = "Debug test (go.mod)",
          request = "launch",
          mode = "test",
          program = "${workspaceFolder}",
        },
        {
          type = "go",
          name = "Attach remote",
          mode = "remote",
          request = "attach",
        },
      }
    end

    -- Keymaps
    vim.keymap.set("n", "<M-1>", function()
      dap.continue()
    end, { desc = "Debug: Continue" })
    vim.keymap.set("n", "<M-2>", function()
      dap.step_over()
    end, { desc = "Debug: Step Over" })
    vim.keymap.set("n", "<M-3>", function()
      dap.step_into()
    end, { desc = "Debug: Step Into" })
    vim.keymap.set("n", "<M-4>", function()
      dap.step_out()
    end, { desc = "Debug: Step Out" })
    vim.keymap.set("n", "<leader>db", function()
      dap.toggle_breakpoint()
    end, { desc = "Debug: Toggle Breakpoint" })
    vim.keymap.set("n", "<leader>dB", function()
      dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end, { desc = "Debug: Set Conditional Breakpoint" })
    vim.keymap.set("n", "<leader>dc", function()
      dap.clear_breakpoints()
    end, { desc = "Debug: Clear Breakpoints" })
    vim.keymap.set("n", "<leader>dr", function()
      dap.repl.open()
    end, { desc = "Debug: Open REPL" })
    vim.keymap.set("n", "<leader>dl", function()
      dap.run_last()
    end, { desc = "Debug: Run Last" })
    vim.keymap.set("n", "<leader>dt", function()
      dap.terminate()
    end, { desc = "Debug: Terminate" })
  end,
}
