local keymap = vim.keymap

-- command aliases
vim.api.nvim_create_user_command("W", "w", {})
vim.api.nvim_create_user_command("Q", "q", {})
vim.api.nvim_create_user_command("WQ", "wq", {})
vim.api.nvim_create_user_command("Wq", "wq", {})

-- general
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- increment/decrement
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- buffers
keymap.set("n", "<Tab>", "<cmd>bnext<CR>", { desc = "Next buffer" })
keymap.set("n", "<S-Tab>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Close buffer" })
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })

-- terminal
keymap.set("n", "<leader>tv", "<cmd>vsplit | terminal<CR>", { desc = "Open terminal in vertical split" })
keymap.set("n", "<leader>th", "<cmd>split | terminal<CR>", { desc = "Open terminal in horizontal split" })

-- lsp (go to definition in new tab)
keymap.set("n", "GD", "<cmd>tab split | lua vim.lsp.buf.definition()<CR>", { desc = "Go to definition in new tab" })

-- disable horizontal scrolling
keymap.set({ "n", "v", "i" }, "<ScrollWheelLeft>", "<Nop>", { desc = "Disable horizontal scroll left" })
keymap.set({ "n", "v", "i" }, "<ScrollWheelRight>", "<Nop>", { desc = "Disable horizontal scroll right" })

-- telescope
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Find recent files" })
keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
keymap.set("n", "<leader>fg", "<cmd>Telescope git_files<cr>", { desc = "Git files" })
keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor" })
keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
keymap.set("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "Find keymaps" })

-- neo-tree
keymap.set("n", "<leader>ee", "<cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" })
keymap.set("n", "<leader>ef", "<cmd>Neotree reveal<CR>", { desc = "Reveal current file in explorer" })

-- trouble
keymap.set("n", "<leader>xw", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Workspace diagnostics" })
keymap.set("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Document diagnostics" })
keymap.set("n", "<leader>xq", "<cmd>Trouble quickfix toggle<CR>", { desc = "Quickfix list" })
keymap.set("n", "<leader>xl", "<cmd>Trouble loclist toggle<CR>", { desc = "Location list" })
keymap.set("n", "<leader>xt", "<cmd>Trouble todo toggle<CR>", { desc = "Todos in trouble" })

-- lazygit
keymap.set("n", "<leader>lg", "<cmd>LazyGit<CR>", { desc = "Open LazyGit" })

-- formatting (manual)
keymap.set({ "n", "v" }, "<leader>mp", function()
  require("conform").format({
    lsp_format = "fallback",
    async = false,
    timeout_ms = 1000,
  })
end, { desc = "Format file or range" })
