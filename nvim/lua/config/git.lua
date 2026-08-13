require("gitsigns").setup({
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
    untracked = { text = "▎" },
  },

  -- Off: the virtual text reflows on every keystroke and lands on the same line
  -- as the diagnostics already there. <leader>gb is the on-demand version.
  current_line_blame = false,

  on_attach = function(bufnr)
    local gs = require("gitsigns")
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    -- h, not gitsigns' own default c: ]c and [c are already the treesitter class
    -- motions in config/treesitter.lua. The diff check is the same guard those
    -- two carry, for the same reason — a rebase or a mergetool is exactly when
    -- nvim is open.
    map({ "n", "x", "o" }, "]h", function()
      if vim.wo.diff then
        return vim.cmd.normal({ "]c", bang = true })
      end
      gs.nav_hunk("next")
    end, "Next hunk")
    map({ "n", "x", "o" }, "[h", function()
      if vim.wo.diff then
        return vim.cmd.normal({ "[c", bang = true })
      end
      gs.nav_hunk("prev")
    end, "Previous hunk")

    map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
    map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")

    -- The visual pair needs the range spelled out: called with no argument
    -- gitsigns only ever takes the hunk under the cursor, selection or not.
    map("v", "<leader>gs", function()
      gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "Stage selected lines")
    map("v", "<leader>gr", function()
      gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "Reset selected lines")

    map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
    map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
    map("n", "<leader>gd", gs.diffthis, "Diff against index")
  end,
})
