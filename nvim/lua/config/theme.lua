-- Nord, dark only, matching the sixteen ANSI slots in alacritty/alacritty.toml.
--
-- 'background' is set here rather than left to the terminal handshake. Neovim's
-- TUI does ask the terminal for its background and would land on dark by itself,
-- but that detection only ever earned its keep while there was a light half to
-- pick; with one palette there is nothing to detect and a lot of machinery that
-- existed only to catch the reply.

vim.o.background = "dark"

-- Only what differs from nordic's own defaults. In particular reduced_blue is
-- left alone: nordic ships its own white rather than nord4, so neither setting
-- would match the terminal's slot 15 anyway, and the default is the brighter of
-- the two against this background — 10.58:1 against 10.05:1.
require("nordic").setup({
  -- On so the terminal's own background shows through and nvim never paints one.
  transparent = { bg = true, float = true },
  -- Both default to true. Off here for the same reason as the is_bold sweep in
  -- eza/theme.yml and the mode block in lualine: no bold anywhere in the stack.
  cursorline = { bold_number = false },
  visual = { bold_number = false },

  -- nordic computes its surfaces and its dim text against its own background,
  -- which is far lighter than the #15181e this terminal paints. Transparency
  -- means nvim never paints that lighter background, so three groups land on a
  -- surface they were not measured for. Re-seated on the palette the sixteen
  -- slots already define; every ratio below is against #15181e.
  --
  -- Fields are mutated rather than replaced so nothing else on the group is lost.
  on_highlight = function(hl)
    -- Shipped at #191d24, which is 1.05:1 against the background — the same
    -- colour, so selecting text looked like nothing happened.
    --
    -- nord3 stepped 10% toward nord4, the same ramp slot 8 is derived from. It
    -- lands on 2.98:1, which is the 3:1 WCAG asks of a non-text UI element, and
    -- a selection is exactly that. Deliberately lighter than the terminal's own
    -- selection (nord2, 2.06:1), so the two no longer match: on a background
    -- this dark nord2 was not carrying far enough inside the editor.
    --
    -- This is the ceiling, not a preference. Going lighter costs the text *in*
    -- the selection: body text is 3.55:1 here and 2.64:1 at slot 8, where a
    -- comment would land on exactly the selection colour and vanish.
    hl.Visual.bg = "#5a6477" -- 2.98:1
    hl.VisualNOS.bg = "#5a6477"
    -- Same 1.05:1 defect. This is the first step of the elevation ramp the rest
    -- of the stack uses — the same value as herdr's panel_bg — and not a nord
    -- grey on purpose: nord1 reads better on its own (1.77:1) but leaves a
    -- selection sitting on the cursor line at 1.17:1, so the end of a partial
    -- selection becomes impossible to place. This keeps that at 1.80:1.
    hl.CursorLine.bg = "#20242d" -- 1.14:1, a wide band rather than a bright one
    -- nord3, at 2.41:1, under the 3:1 floor this stack holds dim text to — and
    -- the same value slot 8 already exists to replace. Kept on slot 8 rather than
    -- raised further so a comment is the same colour in nvim, bat and fish; the
    -- cost is that inside a selection it sits at 1.34:1. Raising this is the one
    -- knob if that ever matters more than the match.
    hl.Comment.fg = "#6f788a" -- 4.00:1 alone, 1.34:1 inside a selection
  end,
})

-- Registered before the colorscheme call below, not after: the autocmd is what
-- applies these on the very first paint too.
--
-- On ColorScheme so a reload doesn't undo it. Groups are read by their generic
-- names (Directory, Normal, Comment) rather than any theme's own, which is what
-- has let this block survive every colorscheme change here untouched.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "nordic",
  callback = function()
    local function fg(group)
      return vim.api.nvim_get_hl(0, { name = group, link = false }).fg
    end
    local set = vim.api.nvim_set_hl

    -- Bold that no option reaches: the first three are Neovim's own defaults, the
    -- headings are nordic's — bold_keywords does not cover them, and they are what
    -- render-markdown paints markdown titles with.
    for _, group in ipairs({
      "PmenuMatch", "PmenuMatchSel", "WinBar",
      "@markup.heading.1.markdown", "@markup.heading.2.markdown",
      "@markup.heading.3.markdown", "@markup.heading.4.markdown",
      "@markup.heading.5.markdown", "@markup.heading.6.markdown",
    }) do
      local h = vim.api.nvim_get_hl(0, { name = group, link = false })
      h.bold, h.cterm = nil, nil
      set(0, group, h)
    end

    set(0, "NeoTreeDirectoryName", { fg = fg("Directory") })
    set(0, "NeoTreeDirectoryIcon", { fg = fg("Directory") })
    set(0, "NeoTreeFileName", { fg = fg("Normal") })
    set(0, "NeoTreeFileNameOpened", { fg = fg("Normal") })
    set(0, "NeoTreeGitIgnored", { fg = fg("Comment"), italic = true })
    set(0, "NeoTreeDotfile", { fg = fg("Comment") })
  end,
})

vim.cmd.colorscheme("nordic")
