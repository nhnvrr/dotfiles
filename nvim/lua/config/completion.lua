-- blink.cmp replaces the builtin vim.lsp.completion setup this config used to
-- carry, and with it three problems: the hack that injected the whole alphabet
-- into the server's triggerCharacters, the <CR> mapping that needed two presses
-- because <C-y> accepts nothing when `noselect` leaves the menu unselected, and
-- the crash when a server registers completion dynamically and
-- server_capabilities.completionProvider is nil.
--
-- Pinned to a version range on purpose. The fuzzy matcher is a Rust library:
-- blink downloads a prebuilt binary only for tagged versions, and on an
-- untagged HEAD it falls back to building it with cargo.
vim.pack.add({
  { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1") },
  "https://github.com/rafamadriz/friendly-snippets",
})

require("blink.cmp").setup({
  -- The "default" preset keeps <CR> and <Tab> out of the accept path: <C-y>
  -- accepts, <C-n>/<C-p> move, and Tab only ever jumps between snippet
  -- placeholders. Enter stays Enter, which is the whole point.
  keymap = { preset = "default" },

  appearance = {
    -- Nerd Font Mono is what the terminal profile loads; every glyph is one
    -- cell, so the menu columns do not shift.
    nerd_font_variant = "mono",
  },

  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
    -- Ghost text is the inline preview of the selected item. Off: it fights
    -- with inlay hints for the same screen space on the right of the cursor.
    ghost_text = { enabled = false },
    menu = {
      draw = { treesitter = { "lsp" } },
    },
  },

  -- Off by default in blink, and the single largest thing missing from the
  -- previous setup: the parameter list of the function being called, while it
  -- is being typed.
  signature = { enabled = true },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },

  fuzzy = {
    implementation = "prefer_rust_with_warning",
  },
})

-- blink does not register its capabilities anywhere by itself. Without this the
-- servers are never told the client supports snippets, resolve support or
-- additionalTextEdits, so auto-import on completion silently does nothing.
--
-- The '*' entry is merged when each client is resolved, which happens on attach
-- — after this file has run — so it reaches every server configured in lsp.lua.
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(nil, true),
})
