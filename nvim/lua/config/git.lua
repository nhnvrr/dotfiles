-- gitsigns. lazygit covers whole-commit work; this covers what lazygit is too
-- heavy for — seeing which lines you changed while you are changing them, and
-- staging one hunk out of a file.
vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })

require("gitsigns").setup({
  -- One-cell ASCII, same reason as neo-tree's markers: the sign column shares
  -- space with diagnostics and dap breakpoints, and an ambiguous-width glyph
  -- shifts everything below it.
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "^" },
    changedelete = { text = "%" },
    untracked = { text = "?" },
  },
  -- Off by default: it redraws on every cursor move. <leader>gb toggles it.
  current_line_blame = false,
  current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
  preview_config = { border = "rounded" },

  on_attach = function(bufnr)
    local gitsigns = require("gitsigns")

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    -- Navigation. Falls back to plain ]c/[c inside a diff, where vim's own
    -- change motion is the right one.
    map("n", "]h", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next")
      end
    end, "Next hunk")

    map("n", "[h", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev")
      end
    end, "Previous hunk")

    map("n", "<leader>gs", gitsigns.stage_hunk, "Stage hunk")
    map("n", "<leader>gr", gitsigns.reset_hunk, "Reset hunk")
    -- "x" and not "v": Select mode must keep <leader> literal so a snippet
    -- placeholder can be typed over.
    map("x", "<leader>gs", function()
      gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "Stage selected lines")
    map("x", "<leader>gr", function()
      gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "Reset selected lines")

    map("n", "<leader>gS", gitsigns.stage_buffer, "Stage buffer")
    map("n", "<leader>gR", gitsigns.reset_buffer, "Reset buffer")
    map("n", "<leader>gp", gitsigns.preview_hunk, "Preview hunk")
    map("n", "<leader>gi", gitsigns.preview_hunk_inline, "Preview hunk inline")
    map("n", "<leader>gb", gitsigns.toggle_current_line_blame, "Toggle line blame")
    map("n", "<leader>gB", function()
      gitsigns.blame_line({ full = true })
    end, "Blame line (full)")
    map("n", "<leader>gd", gitsigns.diffthis, "Diff against index")
    map("n", "<leader>gD", function()
      gitsigns.diffthis("~")
    end, "Diff against last commit")
    map("n", "<leader>gq", gitsigns.setqflist, "Hunks to quickfix")

    map({ "o", "x" }, "ih", gitsigns.select_hunk, "Select hunk")
  end,
})
