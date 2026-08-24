-- neotest. plenary, nvim-nio and treesitter are already loaded by earlier
-- modules; the adapters are what parse each language's test files.
--
-- neotest-golang and not neotest-go: the latter is unmaintained and does not
-- understand table-driven subtests, which is most of what Go tests are.
vim.pack.add({
  "https://github.com/nvim-neotest/neotest",
  "https://github.com/fredrikaverpil/neotest-golang",
  "https://github.com/marilari88/neotest-vitest",
  "https://github.com/nvim-neotest/neotest-jest",
})

local adapters = {
  require("neotest-golang")({
    -- Sends the run through dap-go's dlv configuration, which is what makes
    -- <leader>td work on a Go test rather than only running it.
    dap_go_enabled = true,
  }),
  require("neotest-vitest"),
  require("neotest-jest")({
    jestCommand = "npx jest --",
  }),
}

-- Rust has no third-party adapter: rustaceanvim ships one that drives Cargo
-- properly, including the workspace layout. Guarded because it only exists once
-- rustaceanvim has loaded.
local ok, rustaceanvim_neotest = pcall(require, "rustaceanvim.neotest")
if ok then
  table.insert(adapters, rustaceanvim_neotest)
end

require("neotest").setup({
  adapters = adapters,
  -- The gutter marks are the point: pass/fail per test, in the file, without
  -- reading a terminal. ASCII for the same reason as everywhere else in this
  -- config — these glyphs sit next to Nerd Font ones in the sign column.
  icons = {
    passed = "+",
    failed = "x",
    running = "~",
    skipped = "-",
    unknown = "?",
    running_animated = { "|", "/", "-", "\\" },
  },
  summary = {
    open = "botright vsplit | vertical resize 44",
  },
  output = { open_on_run = false },
  quickfix = {
    -- Populating the quickfix list but not stealing focus: `]q` walks the
    -- failures when you want them, and nothing jumps on its own.
    enabled = true,
    open = false,
  },
})

local neotest = require("neotest")

vim.keymap.set("n", "<leader>tr", function()
  neotest.run.run()
end, { desc = "Run nearest test" })

vim.keymap.set("n", "<leader>tf", function()
  neotest.run.run(vim.fn.expand("%"))
end, { desc = "Run tests in file" })

vim.keymap.set("n", "<leader>ta", function()
  neotest.run.run(vim.uv.cwd())
end, { desc = "Run all tests" })

vim.keymap.set("n", "<leader>tl", function()
  neotest.run.run_last()
end, { desc = "Run last test" })

vim.keymap.set("n", "<leader>ts", function()
  neotest.summary.toggle()
end, { desc = "Toggle test summary" })

vim.keymap.set("n", "<leader>to", function()
  neotest.output.open({ enter = true, auto_close = true })
end, { desc = "Show test output" })

vim.keymap.set("n", "<leader>tp", function()
  neotest.output_panel.toggle()
end, { desc = "Toggle output panel" })

vim.keymap.set("n", "<leader>tx", function()
  neotest.run.stop()
end, { desc = "Stop running test" })

vim.keymap.set("n", "<leader>tw", function()
  neotest.watch.toggle(vim.fn.expand("%"))
end, { desc = "Watch file" })

-- The one that justifies neotest over a terminal split: the same test, stopped
-- at a breakpoint. Rust goes through rustaceanvim, which knows how to build the
-- test binary first; everything else delegates to the dap session in debug.lua.
vim.keymap.set("n", "<leader>td", function()
  if vim.bo.filetype == "rust" then
    -- No bang. In rustaceanvim the bang means "re-run the cached one", not
    -- "the one here": execute_last_debuggable replays whatever ran first and
    -- ignores the cursor entirely, so every press after the first debugs the
    -- wrong test.
    vim.cmd.RustLsp("debuggables")
  else
    neotest.run.run({ strategy = "dap" })
  end
end, { desc = "Debug nearest test" })

-- <leader>tn/tN and not ]t/[t: those two are Neovim 0.12 defaults for :tnext
-- and :tprevious, and shadowing the tag stack to walk test failures is a bad
-- trade — the tag jumps have no other binding, these do.
vim.keymap.set("n", "<leader>tn", function()
  neotest.jump.next({ status = "failed" })
end, { desc = "Next failed test" })

vim.keymap.set("n", "<leader>tN", function()
  neotest.jump.prev({ status = "failed" })
end, { desc = "Previous failed test" })
