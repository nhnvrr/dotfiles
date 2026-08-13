require("blink.cmp").setup({
  -- default keeps <C-y> to accept and leaves <Tab> to snippet jumps only.
  -- super-tab would shadow the indent that <Tab> does everywhere else.
  keymap = {
    preset = "default",
    -- Enter takes the highlighted item while the menu is up, and is a plain
    -- newline when it is not. `fallback` is the half that does the second job:
    -- without it Enter would be swallowed whenever blink has nothing to accept.
    --
    -- This only reads as "accept the suggestion" because list.selection.preselect
    -- defaults to true, so the first item is already highlighted the moment the
    -- menu opens. The flip side is that Enter cannot break a line while the menu
    -- is showing — <C-e> dismisses it first.
    ["<CR>"] = { "accept", "fallback" },
  },

  appearance = {
    -- The Nerd Font here is the Mono variant, where a glyph is exactly one
    -- cell. Say "normal" and every icon in the menu is padded by half a cell.
    nerd_font_variant = "mono",
  },

  completion = {
    -- VS Code shows the doc panel without being asked; the delay keeps it from
    -- flashing on every keystroke while scrolling the list.
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
    ghost_text = { enabled = false },
  },

  signature = { enabled = true },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },

  -- prefer_rust_with_warning: use the prebuilt Rust matcher, and say so out
  -- loud if it ever falls back to the Lua one instead of silently getting slow.
  fuzzy = { implementation = "prefer_rust_with_warning" },
})
