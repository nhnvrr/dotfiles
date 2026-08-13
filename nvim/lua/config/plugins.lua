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
  "https://github.com/AlexvZyl/nordic.nvim",

  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
  "https://github.com/nvim-lualine/lualine.nvim",

  -- lazygit owns committing, history and branches. What it cannot do is mark
  -- which lines of the buffer being edited changed, or stage one hunk without
  -- leaving it.
  "https://github.com/lewis6991/gitsigns.nvim",

  -- No built-in changes or adds a delimiter: ci" only edits what is inside.
  "https://github.com/kylechui/nvim-surround",

  -- undofile is already on; without this the undo *branches* it persists are
  -- reachable only through :undolist plus :undo N.
  "https://github.com/mbbill/undotree",

  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },

  -- Pinned to a tag on purpose: blink ships its Rust fuzzy matcher as a
  -- prebuilt binary attached to tagged releases only. Track main and it falls
  -- back to the slower Lua matcher, or wants a cargo build.
  { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1.*") },
  "https://github.com/rafamadriz/friendly-snippets",

  "https://github.com/stevearc/conform.nvim",
  "https://github.com/b0o/SchemaStore.nvim",

  -- Renders markdown in the buffer itself. No node, no deno, no browser and no
  -- second window — and the markdown/markdown_inline parsers it needs are already
  -- in the treesitter list.
  "https://github.com/MeanderingProgrammer/render-markdown.nvim",

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
