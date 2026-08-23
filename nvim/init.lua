vim.loader.enable()

vim.g.mapleader = " "
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- Builtin plugins this profile never reaches. They are sourced from $VIMRUNTIME
-- during startup unless the flag is set BEFORE it, which is why this sits at the
-- top of the file rather than with the other options. netrw is the one that
-- matters: neo-tree replaces it outright, and left enabled it still registers
-- its autocmds and hijacks a `:e directory/`.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_spellfile_plugin = 1
vim.g.loaded_rplugin = 1

local opt = vim.opt

opt.number = true
opt.signcolumn = "yes"
opt.wrap = false
opt.scrolloff = 4
-- lualine already draws the mode; the builtin message would print it twice.
opt.showmode = false

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

opt.ignorecase = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true

opt.completeopt = { "fuzzy", "menuone", "noselect", "popup" }
opt.updatetime = 250

-- Live preview of :s while it is being typed, in a split showing every line it
-- would touch. The single largest "why did I not have this" option in vim.
opt.inccommand = "split"

-- Relative for the jumps (5k, d3j), absolute on the cursor line so the ruler
-- still says where you are. `number` above is what keeps that one line absolute.
opt.relativenumber = true

-- 300ms and not the 1000ms default: leader is Space, so every chord below waits
-- this long before giving up. Short enough not to feel stuck, long enough that
-- `<leader>ca` typed at speed still lands.
opt.timeoutlen = 300

-- Trailing whitespace and hard tabs are invisible until they break a diff.
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

opt.clipboard = "unnamedplus"
opt.confirm = true
opt.swapfile = false
opt.undofile = true

vim.o.background = "dark"
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")

-- Kanso Ink — the same palette alacritty/alacritty.toml paints slot by slot, so
-- editor and terminal agree on #14171d and body text (#C5C9C7) lands at
-- 10.73:1. A real colorscheme rather than the sixteen ANSI slots: a colorscheme
-- addresses far more groups than sixteen.
--
-- termguicolors is set instead of left to autodetect, which reads COLORTERM —
-- that does not survive every ssh, and without it the theme drops to sixteen
-- colours silently rather than failing.
--
-- vim.pack is Neovim's own (0.12), so this adds a plugin without a plugin
-- manager. It clones on first start; nvim runs bare until it finishes.
vim.o.termguicolors = true
vim.pack.add({ "https://github.com/webhooked/kanso.nvim" })

-- setup() has to run before the colorscheme command: it only stores options,
-- and the highlights are built when the scheme loads.
--
-- transparent drops the Normal background so the terminal shows through, which
-- is what keeps Alacritty's blur visible behind the buffer. It is also what
-- makes the background a single knob — it is painted in one place,
-- alacritty.toml, and nvim follows rather than disagreeing.
--
-- No palette override is needed anywhere: the theme's own bg0 is #14171d, which
-- is exactly what the terminal paints, so the surfaces it defines as a distance
-- above the background land where they were designed to.
require("kanso").setup({
  theme = "ink",
  background = { dark = "ink" },
  transparent = true,
  italics = false,
  bold = false,
})
vim.cmd.colorscheme("kanso-ink")

-- `gruvbox_material_enable_bold = 0` above only reaches the groups the scheme
-- itself declares; bold survives in the builtins it leaves alone and in every
-- plugin group. This sweeps all of them, and re-runs on ColorScheme because
-- loading a scheme rebuilds the table.
--
-- Linked groups come back as { link = "Other" } with no bold key, so the guard
-- skips them and the link is left intact rather than flattened into a copy.
local function strip_bold()
  for name, attrs in pairs(vim.api.nvim_get_hl(0, {})) do
    if attrs.bold or (attrs.cterm and attrs.cterm.bold) then
      attrs.bold = nil
      if attrs.cterm then
        attrs.cterm.bold = nil
      end
      -- nvim_get_hl reports default = true for groups declared with hi default,
      -- and nvim_set_hl reads that flag as "skip if the group already exists".
      -- Handing the table straight back would silently do nothing.
      attrs.default = nil
      vim.api.nvim_set_hl(0, name, attrs)
    end
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    -- Deferred so plugins that rebuild their own groups on ColorScheme run first.
    vim.schedule(strip_bold)
  end,
})

-- VimEnter and not a bare call here: the plugins set up further down this file
-- define their groups after this point, and Telescope defines some of its own
-- on first open. This pass runs once the whole config has been read.
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.schedule(strip_bold)
  end,
})
strip_bold()

vim.diagnostic.config({
  severity_sort = true,
  signs = true,
  underline = true,
  virtual_text = { severity = vim.diagnostic.severity.ERROR },
})

-- neo-tree pulls three repos of its own: plenary and nui are hard requirements
-- it errors without, devicons is what draws the per-filetype icons.
--
-- The major is pinned rather than a branch: the v2 to v3 rewrite was breaking,
-- and an unpinned add would take a future v4 the same way.
vim.pack.add({
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = vim.version.range("3") },
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
})

-- Filetype icons are left at their defaults: they are already Nerd Font glyphs,
-- and the terminal profile loads the Mono build where each one is one cell.
--
-- The git markers are not. Two of the defaults — `✚` and `✖` — are East-Asian
-- Ambiguous, so their width depends on a terminal setting rather than on the
-- font, and next to the one-cell Nerd Font glyphs the column shifts by a cell
-- as files change state. These are git's own porcelain letters, every one of
-- them ASCII and one cell wide, so the column never moves.
--
-- unstaged is empty on purpose: unstaged is the normal case, and printing it
-- next to the change type gives every modified file two markers instead of one.
-- Only the exception is drawn — `=` for what is already staged. ignored is
-- empty too, since filtered_items hides those anyway.
require("neo-tree").setup({
  close_if_last_window = true,
  window = { width = 32 },
  default_component_configs = {
    git_status = {
      symbols = {
        added     = "+",
        modified  = "~",
        deleted   = "-",
        renamed   = ">",
        untracked = "?",
        conflict  = "!",
        staged    = "=",
        unstaged  = "",
        ignored   = "",
      },
    },
  },
  filesystem = {
    -- This is a dotfiles repo: hiding dotfiles would hide the whole tree.
    filtered_items = { hide_dotfiles = false, hide_gitignored = true },
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
  },
})

vim.keymap.set("n", "<leader>e", "<Cmd>Neotree toggle reveal<CR>", { desc = "Toggle file tree" })

-- The builtin statusline cannot show diagnostic counts or the git branch
-- without hand-writing a vim.o.statusline expression and its refresh; that is
-- the limit being bought out here, not the looks. Unpinned like plenary and
-- nui: lualine publishes no tags, so a range would have nothing to match.
--
-- devicons is already loaded above for neo-tree.
vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })

-- kanso.nvim ships its own lualine theme, so this is the palette itself
-- and not the auto theme's guess at it. It arrives with solid backgrounds and a
-- bold mode section; both are stripped here rather than after setup(), because
-- lualine copies the table it is given and rebuilds these groups on
-- ColorScheme, which would undo a later override.
local function luminance(hex)
  local function channel(value)
    value = tonumber(value, 16) / 255
    return value <= 0.04045 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4
  end
  local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
  if not r then
    return nil
  end
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

local lualine_theme = require("lualine.themes.kanso")
for _, mode in pairs(lualine_theme) do
  for _, section in pairs(mode) do
    -- The mode section is a coloured chip with near-black text on it. Dropping
    -- the chip without touching the text leaves near-black on black, which is
    -- invisible — so where the text is the darker of the two, the chip's own
    -- colour becomes the text colour. That is what carried the mode anyway.
    local fg, bg = luminance(section.fg or ""), luminance(section.bg or "")
    if fg and bg and fg < bg then
      section.fg = section.bg
    end
    section.bg = "NONE"
    section.gui = nil
  end
end

require("lualine").setup({
  options = {
    theme = lualine_theme,
    -- Plain separators: the powerline arrows need a glyph that changes width
    -- between Nerd Font builds, and the profile loads the Mono one.
    section_separators = "",
    component_separators = "|",
    globalstatus = true,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "diagnostics", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
  extensions = { "neo-tree" },
})

-- Telescope. plenary is already loaded above for neo-tree, and so is devicons,
-- which is what draws the filetype glyph in the results list.
--
-- telescope-fzf-native is a C extension that has to be compiled, and the hook
-- below is what compiles it. It is not decoration: without it the sorter is
-- Telescope's own Lua fuzzy matcher, which scores differently from the fzf
-- binary the shell uses on Ctrl-T. With it, the same query ranks the same way
-- in both places.
--
-- Unpinned: telescope's last tag is 0.1.8, and master is where the fixes for
-- Neovim 0.12 landed. fzf-native publishes no tags at all.
--
-- live_grep shells out to ripgrep, which is why Brewfile declares it: every rg
-- on this machine otherwise belongs to some editor extension, not the profile.

-- Registered before the add, because PackChanged fires during it — on first
-- clone there is no second chance to run the build.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(args)
    local data = args.data
    if data.spec.name ~= "telescope-fzf-native.nvim" or data.kind == "delete" then
      return
    end
    local result = vim.system({ "make" }, { cwd = data.path, text = true }):wait()
    if result.code ~= 0 then
      vim.notify("telescope-fzf-native: make failed\n" .. (result.stderr or ""), vim.log.levels.ERROR)
    end
  end,
})

vim.pack.add({
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
})

local telescope = require("telescope")

telescope.setup({
  defaults = {
    -- Same shape as the neo-tree markers: one-cell ASCII rather than glyphs
    -- whose width depends on a terminal setting.
    prompt_prefix = "> ",
    selection_caret = "> ",
    -- flex is horizontal (matches left, preview right) and only stacks the
    -- preview below when the window is narrower than flip_columns.
    layout_strategy = "flex",
    layout_config = {
      width = 0.9,
      height = 0.9,
      prompt_position = "top",
      flip_columns = 120,
      horizontal = { preview_width = 0.55 },
      vertical = { preview_height = 0.45 },
    },
    sorting_strategy = "ascending",
    path_display = { "truncate" },
    -- The default ignores nothing, so .git objects flood a --hidden search.
    file_ignore_patterns = { "^%.git/" },
  },
  pickers = {
    find_files = {
      -- Same switches as FZF_CTRL_T_COMMAND in zsh/zshrc.
      find_command = { "fd", "--type", "f", "--hidden", "--follow", "--exclude", ".git" },
    },
  },
  extensions = {
    fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true },
  },
})

-- After setup(), and guarded: the extension is a compiled .so, and if the build
-- above failed this would error out of the whole config instead of falling back
-- to the Lua sorter.
pcall(telescope.load_extension, "fzf")

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find file" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Grep in project" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffer" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help tag" })
vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Find recent file" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Find diagnostic" })
vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Grep in current file" })

local function root(markers)
  return function(bufnr, on_dir)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path ~= "" then
      on_dir(vim.fs.root(path, markers) or vim.fs.dirname(path))
    end
  end
end

vim.lsp.config("vtsls", {
  cmd = { "vtsls", "--stdio" },
  filetypes = { "typescript", "typescriptreact" },
  root_dir = root({ "tsconfig.json", "jsconfig.json", "package.json", ".git" }),
  on_init = function(client)
    client.server_capabilities.semanticTokensProvider = nil
  end,
  settings = {
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      preferences = { importModuleSpecifier = "shortest" },
    },
    vtsls = { autoUseWorkspaceTsdk = true },
  },
})

vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork" },
  root_dir = root({ "go.work", "go.mod", ".git" }),
  settings = {
    gopls = {
      gofumpt = true,
      usePlaceholders = true,
    },
  },
})

vim.lsp.config("rust_analyzer", {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_dir = root({ "Cargo.toml", ".git" }),
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = false,
    },
  },
})

vim.lsp.config("bashls", {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh" },
  root_dir = root({ ".git" }),
})

vim.lsp.config("yamlls", {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml" },
  root_dir = root({ ".git" }),
  settings = {
    yaml = {
      keyOrdering = false,
      validate = true,
    },
    redhat = { telemetry = { enabled = false } },
  },
})

vim.lsp.config("jsonls", {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_dir = root({ "package.json", ".git" }),
  settings = {
    json = { validate = { enable = true } },
  },
})

vim.lsp.enable({ "vtsls", "gopls", "rust_analyzer", "bashls", "yamlls", "jsonls" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method("textDocument/completion") then
      return
    end

    local provider = client.server_capabilities.completionProvider
    local triggers = provider.triggerCharacters or {}
    local present = {}
    for _, char in ipairs(triggers) do
      present[char] = true
    end
    for char in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"):gmatch(".") do
      if not present[char] then
        triggers[#triggers + 1] = char
      end
    end
    provider.triggerCharacters = triggers

    vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get, {
      buffer = args.buf,
      desc = "Trigger completion",
    })
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, {
      buffer = args.buf,
      desc = "Go to definition",
    })
  end,
})

-- Leaves insert mode without reaching for Esc. The cost is that a literal `j`
-- holds for 'timeoutlen' before it prints, waiting to see if a `k` follows.
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true })

vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })

vim.keymap.set("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true })

local function toml_section(contents, name)
  local escaped = name:gsub("%.", "%%.")
  return contents:match("%[" .. escaped .. "%](.-)\n%[")
    or contents:match("%[" .. escaped .. "%](.*)$")
end

local function rust_edition(path)
  local dir = vim.fs.dirname(path)
  while dir do
    local manifest = vim.fs.joinpath(dir, "Cargo.toml")
    if vim.fn.filereadable(manifest) == 1 then
      local contents = table.concat(vim.fn.readfile(manifest), "\n")
      for _, section_name in ipairs({ "package", "workspace.package" }) do
        local section = toml_section(contents, section_name)
        local edition = section and section:match("\n%s*edition%s*=%s*[\"'](%d+)[\"']")
        if edition then
          return edition
        end
      end
    end

    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end
  return "2024"
end

local formatter_for = {
  typescript = function(path)
    return { "prettier", "--stdin-filepath", path }
  end,
  typescriptreact = function(path)
    return { "prettier", "--stdin-filepath", path }
  end,
  go = function()
    return { "gofumpt" }
  end,
  rust = function(path)
    return { "rustfmt", "--edition", rust_edition(path), "--emit", "stdout" }
  end,
  sh = function(path)
    return { "shfmt", "-filename", path }
  end,
  yaml = function(path)
    return { "prettier", "--stdin-filepath", path }
  end,
  json = function(path)
    return { "prettier", "--stdin-filepath", path }
  end,
  jsonc = function(path)
    return { "prettier", "--stdin-filepath", path }
  end,
}

local function format_buffer(bufnr)
  local build_command = formatter_for[vim.bo[bufnr].filetype]
  if not build_command then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    error("Formatter needs a file name")
  end

  local command = build_command(path)
  if vim.fn.executable(command[1]) ~= 1 then
    error("Formatter not found: " .. command[1])
  end

  local input = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  if vim.bo[bufnr].endofline then
    input = input .. "\n"
  end

  local result = vim.system(command, {
    cwd = vim.fs.dirname(path),
    stdin = input,
    text = true,
  }):wait(5000)

  if result.code ~= 0 then
    local message = vim.trim(result.stderr or "formatter failed")
    error(command[1] .. ": " .. message)
  end

  local output = (result.stdout or ""):gsub("\r\n", "\n")
  if output == input then
    return
  end

  local ends_with_newline = output:sub(-1) == "\n"
  local lines = vim.split(output, "\n", { plain = true })
  if ends_with_newline then
    table.remove(lines)
  end
  if #lines == 0 then
    lines = { "" }
  end

  local view = vim.fn.winsaveview()
  pcall(vim.cmd.undojoin)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].endofline = ends_with_newline
  vim.fn.winrestview(view)
end

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(args)
    format_buffer(args.buf)
  end,
})

vim.api.nvim_create_user_command("Format", function()
  format_buffer(0)
end, { desc = "Format the current buffer" })

vim.keymap.set("n", "<leader>f", "<Cmd>Format<CR>", { desc = "Format buffer" })


-- ─── splits ──────────────────────────────────────────────────────────────────
--
-- sv/sh and not the builtin <C-w>v / <C-w>s: those are two chords deep and this
-- is the one window operation used constantly. The letters follow the shape of
-- the resulting divider, not the direction of the new pane — sv puts a vertical
-- line down the middle, sh a horizontal one across.
vim.keymap.set("n", "<leader>sv", "<Cmd>vsplit<CR>", { desc = "Split vertically" })
vim.keymap.set("n", "<leader>sh", "<Cmd>split<CR>", { desc = "Split horizontally" })
vim.keymap.set("n", "<leader>sc", "<Cmd>close<CR>", { desc = "Close split" })
vim.keymap.set("n", "<leader>so", "<Cmd>only<CR>", { desc = "Close other splits" })
vim.keymap.set("n", "<leader>s=", "<C-w>=", { desc = "Equalise splits" })

-- Moving between them, since a split is worth little without this.
for key, dir in pairs({ h = "h", j = "j", k = "k", l = "l" }) do
  vim.keymap.set("n", "<C-" .. key .. ">", "<C-w>" .. dir, { desc = "Focus split " .. dir })
end

-- ─── writing code: the language keymaps ──────────────────────────────────────
--
-- Buffer-local and attached on LspAttach, not global: bound globally these would
-- fire in a buffer with no server and error, and `gd` above already follows this
-- pattern. Everything here is a builtin vim.lsp.buf call — no plugin involved.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end
    map("K", vim.lsp.buf.hover, "Hover docs")
    map("gr", vim.lsp.buf.references, "References")
    map("gi", vim.lsp.buf.implementation, "Implementation")
    map("gy", vim.lsp.buf.type_definition, "Type definition")
    map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>ds", vim.diagnostic.open_float, "Diagnostic under cursor")
    -- Errors only. Walking every hint on a TypeScript buffer is unusable.
    map("]d", function()
      vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
    end, "Next error")
    map("[d", function()
      vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
    end, "Previous error")
  end,
})

-- Per-language, and only what the generic LSP maps above cannot do.
--
-- vtsls exposes the TypeScript-specific refactors as workspace commands rather
-- than code actions, so they have to be sent through executeCommand with the
-- buffer URI — there is no vim.lsp.buf wrapper for them.
local function vtsls(command)
  return function()
    vim.lsp.buf_request(0, "workspace/executeCommand", {
      command = command,
      arguments = { vim.uri_from_bufnr(0) },
    })
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  callback = function(args)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end
    map("<leader>co", vtsls("typescript.organizeImports"), "Organize imports")
    map("<leader>cm", vtsls("typescript.addMissingImports"), "Add missing imports")
    map("<leader>cu", vtsls("typescript.removeUnusedImports"), "Remove unused imports")
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function(args)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end
    -- Clippy is the one that catches what rustc accepts but nobody wants; check
    -- is only "does it compile". Both run in a terminal split rather than
    -- through :make, so the output scrolls and cargo's colours survive.
    map("<leader>cc", "<Cmd>split | terminal cargo clippy --all-targets<CR>", "cargo clippy")
    map("<leader>ck", "<Cmd>split | terminal cargo check<CR>", "cargo check")
    map("<leader>ct", "<Cmd>split | terminal cargo test<CR>", "cargo test")
    map("<leader>cr", "<Cmd>split | terminal cargo run<CR>", "cargo run")
    -- rust-analyzer's own expansion, which no other server has an analogue for.
    map("<leader>ce", function()
      vim.lsp.buf_request(0, "rust-analyzer/expandMacro", vim.lsp.util.make_position_params(0, "utf-8"))
    end, "Expand macro")
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc" },
  callback = function(args)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end
    -- jq and not the LSP: jsonls validates and completes against a schema but
    -- has no opinion on shape. `%!` filters the whole buffer through the
    -- command, so a failed parse leaves an error in the buffer and `u` undoes it.
    map("<leader>cp", "<Cmd>%!jq .<CR>", "Pretty-print with jq")
    map("<leader>cm", "<Cmd>%!jq -c .<CR>", "Minify with jq")
    map("<leader>cs", "<Cmd>%!jq -S .<CR>", "Sort keys with jq")
  end,
})


-- ─── ergonomics ──────────────────────────────────────────────────────────────
--
-- Everything here is a builtin. No plugin loads for any of it, which is the
-- point: the cost of the config is what it does at startup, and this costs
-- nothing measurable.

-- Esc clears the search highlight as well as leaving the mode. Without this the
-- highlight from the last search stays lit until :noh, which nobody types.
vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Keep the cursor in the middle when jumping. Half-page scrolling and search
-- both dump you at the edge of the screen otherwise, and reading around the
-- landing point is most of what happens next.
for _, key in ipairs({ "<C-d>", "<C-u>", "n", "N" }) do
  vim.keymap.set("n", key, key .. "zz", { desc = "Jump and centre" })
end

-- Move the selection, reindenting as it goes. The one refactor motion that is
-- pure ceremony without a mapping: dd, navigate, p, re-indent.
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Stay in visual mode after indenting, so > > > is one keypress repeated.
vim.keymap.set("v", "<", "<gv", { desc = "Indent left, keep selection" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right, keep selection" })

-- Paste over a selection without losing the register. The default swaps the
-- yanked text for whatever was replaced, which makes a second paste useless.
vim.keymap.set("v", "p", '"_dP', { desc = "Paste without clobbering register" })

-- Delete without touching the unnamed register, for the same reason.
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete to black hole" })

-- Resize the splits from <leader>s..., matching the split maps above.
vim.keymap.set("n", "<C-Up>", "<Cmd>resize +2<CR>", { desc = "Grow split" })
vim.keymap.set("n", "<C-Down>", "<Cmd>resize -2<CR>", { desc = "Shrink split" })
vim.keymap.set("n", "<C-Left>", "<Cmd>vertical resize -4<CR>", { desc = "Narrow split" })
vim.keymap.set("n", "<C-Right>", "<Cmd>vertical resize +4<CR>", { desc = "Widen split" })

-- Buffers, since this profile has no tabline.
vim.keymap.set("n", "<S-l>", "<Cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-h>", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bd", "<Cmd>bdelete<CR>", { desc = "Close buffer" })

-- A visible flash on whatever was just yanked, so a large yank is confirmed
-- without checking the register.
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- Reopen a file where it was left. The mark survives in the shada file; the
-- guard skips it when the line no longer exists, which happens after a rebase.
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Diagnostics: the text on the line that has one, the rest in the float. Left
-- at the default every error prints its full message inline and wraps the
-- window on a TypeScript buffer.
vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 2, source = "if_many" },
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
})
