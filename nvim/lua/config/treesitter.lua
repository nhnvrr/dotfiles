local treesitter = require("nvim-treesitter")

-- nvim-treesitter's rewritten `main` branch keeps its bundled queries under a
-- nested runtime/ directory. Plugin managers with an explicit rtp option add
-- it themselves; vim.pack only adds the repository root. Parsers can therefore
-- load successfully while `queries/typescript/highlights.scm` remains invisible
-- (and Tree-sitter looks active but paints nothing). Add that runtime directly,
-- which also makes the setup independent of stale query symlinks left by an old
-- plugin manager.
do
  local module = vim.api.nvim_get_runtime_file("lua/nvim-treesitter/init.lua", false)[1]
  if module then
    local plugin_root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(module)))
    local query_runtime = vim.fs.joinpath(plugin_root, "runtime")
    if vim.uv.fs_stat(query_runtime) then
      vim.opt.runtimepath:append(query_runtime)
    end
  end
end

treesitter.setup({})
require("nvim-treesitter-textobjects").setup({})

-- install() costs a few ms even with nothing to do, and every startup pays it,
-- so it only runs against what is actually missing.
do
  local have = {}
  for _, parser in ipairs(treesitter.get_installed("parsers")) do
    have[parser] = true
  end
  local missing = vim.tbl_filter(function(parser) return not have[parser] end, {
    "bash", "diff", "dockerfile", "git_rebase", "gitcommit", "go", "gomod", "gosum",
    -- No jsonc parser exists; the json one covers it via filetype.
    "hcl", "javascript", "json", "lua", "markdown", "markdown_inline",
    "ruby", "rust", "sql", "toml", "tsx", "typescript", "yaml",
  })
  if #missing > 0 then
    treesitter.install(missing)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    -- Errors on a filetype whose parser is missing or still installing, which
    -- is every filetype on a cold checkout.
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

local function jump(dir, obj, builtin)
  return function()
    -- ]c and [c already mean next/previous change in diff mode, and a rebase
    -- or a mergetool is exactly when nvim is open.
    if builtin and vim.wo.diff then
      return vim.cmd.normal({ builtin, bang = true })
    end
    local move = require("nvim-treesitter-textobjects.move")
    move[dir == "next" and "goto_next_start" or "goto_previous_start"](obj, "textobjects")
  end
end

for key, spec in pairs({ f = { "@function.outer" }, c = { "@class.outer", "c" } }) do
  vim.keymap.set({ "n", "x", "o" }, "]" .. key, jump("next", spec[1], spec[2] and "]c"),
    { desc = "Next " .. (key == "f" and "function" or "class") })
  vim.keymap.set({ "n", "x", "o" }, "[" .. key, jump("prev", spec[1], spec[2] and "[c"),
    { desc = "Previous " .. (key == "f" and "function" or "class") })
end

for lhs, obj in pairs({
  af = "@function.outer", ["if"] = "@function.inner",
  ac = "@class.outer", ic = "@class.inner",
}) do
  vim.keymap.set({ "x", "o" }, lhs, function()
    require("nvim-treesitter-textobjects.select").select_textobject(obj, "textobjects")
  end, { desc = "Select " .. obj })
end
