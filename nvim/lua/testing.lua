vim.pack.add({
  "https://github.com/nvim-neotest/neotest",
  "https://github.com/fredrikaverpil/neotest-golang",
  "https://github.com/marilari88/neotest-vitest",
  "https://github.com/nvim-neotest/neotest-jest",
  "https://github.com/rouge8/neotest-rust",
})

local neotest = require("neotest")
neotest.setup({
  adapters = {
    require("neotest-golang")({ dap_go_enabled = true }),
    require("neotest-vitest"),
    require("neotest-jest")({ jestCommand = "npx jest --" }),
    require("neotest-rust"),
  },
  icons = {
    passed = "+", failed = "x", running = "~", skipped = "-", unknown = "?",
    running_animated = { "|", "/", "-", "\\" },
  },
  summary = { open = "botright vsplit | vertical resize 44" },
  output = { open_on_run = false },
  quickfix = { enabled = true, open = false },
})

local map = vim.keymap.set
map("n", "<leader>tr", function() neotest.run.run() end, { desc = "Nearest" })
map("n", "<leader>tf", function() neotest.run.run(vim.fn.expand("%")) end, { desc = "File" })
map("n", "<leader>ta", function() neotest.run.run(vim.uv.cwd()) end, { desc = "All" })
map("n", "<leader>tl", function() neotest.run.run_last() end, { desc = "Last" })
map("n", "<leader>td", function() neotest.run.run({ strategy = "dap" }) end, { desc = "Debug nearest" })
map("n", "<leader>ts", function() neotest.summary.toggle() end, { desc = "Summary" })
map("n", "<leader>to", function() neotest.output.open({ enter = true, auto_close = true }) end, { desc = "Output" })
map("n", "<leader>tp", function() neotest.output_panel.toggle() end, { desc = "Output panel" })
map("n", "<leader>tw", function() neotest.watch.toggle(vim.fn.expand("%")) end, { desc = "Watch file" })
map("n", "<leader>tx", function() neotest.run.stop() end, { desc = "Stop" })
map("n", "]t", function() neotest.jump.next({ status = "failed" }) end, { desc = "Next failed test" })
map("n", "[t", function() neotest.jump.prev({ status = "failed" }) end, { desc = "Previous failed test" })
