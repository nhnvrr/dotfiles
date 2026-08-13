-- vim.pack has no build hook of its own; PackChanged is the seam. It fires on
-- install and update, and also on delete, hence the kind check.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "telescope-fzf-native.nvim" and ev.data.kind ~= "delete" then
      local done = vim.system({ "make" }, { cwd = ev.data.path }):wait()
      if done.code ~= 0 then
        vim.notify("fzf-native build failed: " .. (done.stderr or ""), vim.log.levels.ERROR)
      end
    end
  end,
})

vim.pack.add({
  -- One per theme family, because no single colorscheme plugin carries all three.
  -- Each ships both halves and switches on vim.o.background; config/theme.lua maps
  -- the family, which it reads from the deployed alacritty theme.
  "https://github.com/maxmx03/solarized.nvim",
  "https://github.com/ellisonleao/gruvbox.nvim",
  "https://github.com/olimorris/onedarkpro.nvim",

  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
  "https://github.com/nvim-lualine/lualine.nvim",

  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },

  -- Pinned to a tag on purpose: blink ships its Rust fuzzy matcher as a
  -- prebuilt binary attached to tagged releases only. Track main and it falls
  -- back to the slower Lua matcher, or wants a cargo build.
  { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1.*") },
  "https://github.com/rafamadriz/friendly-snippets",

  "https://github.com/stevearc/conform.nvim",
  "https://github.com/b0o/SchemaStore.nvim",

  -- Owns rust-analyzer end to end — LSP, inlay hints, runnables and the DAP
  -- wiring. Configured through vim.g.rustaceanvim, never vim.lsp.enable: doing
  -- both starts two clients on the same buffer.
  "https://github.com/mrcjkb/rustaceanvim",

  "https://github.com/mfussenegger/nvim-dap",
  "https://github.com/nvim-neotest/nvim-nio",
  "https://github.com/rcarriga/nvim-dap-ui",
  "https://github.com/theHamsta/nvim-dap-virtual-text",
  "https://github.com/leoluz/nvim-dap-go",

  -- Only for the two debug adapters Homebrew does not carry (js-debug-adapter,
  -- codelldb). Every language server still comes from the Brewfile.
  "https://github.com/mason-org/mason.nvim",
})
