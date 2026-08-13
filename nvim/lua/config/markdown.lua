-- In-buffer markdown rendering. Only what differs from the plugin's defaults.
--
-- The parsers it needs, markdown and markdown_inline, are already in the list in
-- config/treesitter.lua, so this adds no parser and no external binary.

require("render-markdown").setup({
  -- Both default to 'full', which paints the background across the whole window.
  -- 'block' makes it hug the text instead, so a code block reads as a surface
  -- rather than a slab and headings do not stripe the buffer edge to edge.
  heading = { width = "block", sign = false },
  code = { width = "block", sign = false },
})
