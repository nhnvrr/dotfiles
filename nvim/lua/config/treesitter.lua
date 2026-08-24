local augroup = vim.api.nvim_create_augroup("dotfiles.treesitter", { clear = true })

-- This is nvim-treesitter's `main` branch, whose API shares almost nothing with
-- the `master` one that most documentation still describes. There is no
-- configs.lua and no `highlight = { enable = true }`: setup() only decides where
-- parsers land, installing is a separate call, and the highlighting itself is
-- turned on by Neovim rather than by the plugin.
--
-- Compiling parsers needs tree-sitter-cli >= 0.26.1 and a C compiler, which is
-- why Brewfile declares the former; the npm build of the CLI is a different
-- program and does not work here.
vim.pack.add({
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
})

require("nvim-treesitter").setup({})

-- Asynchronous, and deliberately not waited on: a cold start would otherwise
-- block for minutes compiling thirty parsers. Missing ones simply have no
-- highlighting until the install finishes, and `:e` afterwards picks them up.
--
-- The trap: install() is a no-op when the .so is already on disk, and it is the
-- same call that symlinks the query files. A parser left behind by a previous
-- plugin manager therefore satisfies the check while its queries still point at
-- that manager's deleted directory — and a dangling query is silent, because
-- vim.treesitter.start() attaches happily and then has nothing to apply, so the
-- buffer renders in a single colour. `:checkhealth vim.treesitter` names it;
-- install(..., { force = true }) is what repairs it.
require("nvim-treesitter").install({
  "bash",
  "css",
  "diff",
  "dockerfile",
  "git_rebase",
  "gitcommit",
  "gitignore",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "query",
  "regex",
  "rust",
  "sql",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
})

-- jsonc has no parser of its own and reuses json's, so it is registered rather
-- than installed. Asking install() for it only prints "unsupported language".
vim.treesitter.language.register("json", "jsonc")

require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true },
})

-- Highlighting and indentation are Neovim's, not the plugin's: vim.treesitter
-- .start() is the whole switch. pcall because a filetype whose parser has not
-- finished installing — or has none at all — throws, and an unguarded throw
-- here fires on every single buffer open.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  callback = function(args)
    if not pcall(vim.treesitter.start) then
      return
    end
    -- Only after start() succeeded. Pointing indentexpr at a language with no
    -- parser makes every `==` an error.
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

local ts_select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")
local swap = require("nvim-treesitter-textobjects.swap")

-- Text objects, in x and o only. Never "v": that mode also covers Select, where
-- these letters have to stay literal so snippet placeholders can be typed over.
--
-- ab/ib shadow the builtin parenthesis objects (`:h v_ab`, the same thing as
-- a(/i(). Taken knowingly: a(/i( and a)/i) stay bound, so nothing is lost, and
-- a treesitter @block is the actual braced body in Rust, Go and TypeScript,
-- which is what gets selected far more often than a paren pair.
for lhs, capture in pairs({
  ["af"] = "@function.outer",
  ["if"] = "@function.inner",
  ["ac"] = "@class.outer",
  ["ic"] = "@class.inner",
  ["aa"] = "@parameter.outer",
  ["ia"] = "@parameter.inner",
  ["ab"] = "@block.outer",
  ["ib"] = "@block.inner",
}) do
  vim.keymap.set({ "x", "o" }, lhs, function()
    ts_select.select_textobject(capture, "textobjects")
  end, { desc = "Select " .. capture })
end

vim.keymap.set({ "n", "x", "o" }, "]f", function()
  move.goto_next_start("@function.outer", "textobjects")
end, { desc = "Next function" })

vim.keymap.set({ "n", "x", "o" }, "[f", function()
  move.goto_previous_start("@function.outer", "textobjects")
end, { desc = "Previous function" })

-- Reordering arguments is a constant edit in Rust and Go, and the alternative
-- is a delete, a motion and a paste that gets the commas wrong.
vim.keymap.set("n", "<leader>a", function()
  swap.swap_next("@parameter.inner")
end, { desc = "Swap argument right" })

vim.keymap.set("n", "<leader>A", function()
  swap.swap_previous("@parameter.inner")
end, { desc = "Swap argument left" })
