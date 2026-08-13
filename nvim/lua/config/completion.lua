require("blink.cmp").setup({
  -- default keeps <C-y> to accept and leaves <Tab> to snippet jumps only.
  -- super-tab would shadow the indent that <Tab> does everywhere else.
  keymap = { preset = "default" },

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
