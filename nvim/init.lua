vim.loader.enable()

vim.g.mapleader = " "
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

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

opt.clipboard = "unnamedplus"
opt.confirm = true
opt.swapfile = false
opt.undofile = true

vim.o.background = "dark"
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")

-- Jellybeans, the same palette ghostty/config paints slot by slot, so editor and
-- terminal agree on #242424 and body text (#e8e8d3) lands at 12.50:1. A real
-- colorscheme rather than inheriting the sixteen ANSI slots: a colorscheme
-- addresses far more groups than sixteen.
--
-- termguicolors is set instead of left to autodetect, which reads COLORTERM —
-- that does not survive every ssh, and without it the theme drops to sixteen
-- colours silently rather than failing.
--
-- vim.pack is Neovim's own (0.12), so this adds a plugin without a plugin
-- manager. It clones on first start; nvim runs bare until it finishes.
--
-- Unpinned, same as lualine below: this plugin publishes no tags, so a version
-- range would have nothing to match.
vim.o.termguicolors = true
vim.pack.add({ "https://github.com/wtfox/jellybeans.nvim" })

-- setup() has to run before the colorscheme command: it only stores options,
-- and the highlights are built when the scheme loads.
--
-- plugins.all and not the default plugins.auto: auto-detection is a check for
-- `package.loaded.lazy`, and there is no plugin manager here, so it would
-- silently skip the neo-tree, lualine and telescope groups.
--
-- transparent drops the Normal background so the terminal shows through, which
-- is what keeps Ghostty's blur visible behind the buffer. It is also what makes
-- the background a single knob: jellybeans' own is #151515, ghostty/config
-- paints #242424, and because nvim never draws one it follows the terminal
-- rather than disagreeing with it.
--
-- on_colors relights five palette entries.
--
-- `old_brick` is jellybeans' dark red and lands at 2.10:1 on this background —
-- it is what paints neo-tree's deleted and conflict markers, and it is
-- unreadable there. The replacement is the same hex ghostty/config uses for
-- ANSI slot 9, which is the same colour for the same reason, so the two stay
-- in lockstep.
--
-- The other three are the greys jellybeans defines *relative to* its own
-- #151515 background, which ghostty/config no longer paints. Left alone they do
-- not merely shift, they invert: every one of them is darker than #242424, so
-- a Telescope prompt or a selected row reads as a dark hole instead of a raised
-- panel. Each is relit to the value that reproduces its original ratio, because
-- what these encode is a distance from the background, not a colour:
--
--   grey_one     #1c1c1c  1.07:1   ->  #292929   selected row
--   mine_shaft   #1f1f1f  1.11:1   ->  #2c2c2c   Telescope's prompt fill
--   grey_three   #333333  1.45:1   ->  #3e3e3e   borders, Pmenu, indent markers
--
-- `background` itself is relit for the same reason. transparent = true above
-- leaves the main windows at NONE, so the buffer is unaffected — but the flat_ui
-- Telescope groups paint it *solid*, and the picker covers most of the screen.
-- Without this it would open as a #151515 slab on a #242424 terminal, which is
-- both visibly wrong and the near-black this palette moved away from.
require("jellybeans").setup({
  transparent = true,
  italics = false,
  bold = false,
  flat_ui = true,
  plugins = { all = true },
  on_colors = function(colors)
    colors.old_brick = "#e06060"
    colors.background = "#242424"
    colors.grey_one = "#292929"
    colors.mine_shaft = "#2c2c2c"
    colors.grey_three = "#3e3e3e"
  end,
})
vim.cmd.colorscheme("jellybeans")

-- `bold = false` above only reaches the groups jellybeans itself declares; bold
-- survives in the builtins it leaves alone and in every plugin group. This
-- sweeps all of them, and re-runs on ColorScheme because loading a scheme
-- rebuilds the table.
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
-- and ghostty/config loads the Mono build where each one is one cell.
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

-- jellybeans.nvim ships its own lualine theme, so this is the palette itself
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

local lualine_theme = require("lualine.themes.jellybeans-nvim")
for _, mode in pairs(lualine_theme) do
  for _, section in pairs(mode) do
    -- The mode section is a coloured chip with near-black text on it. Dropping
    -- the chip without touching the text leaves #000000 on #242424, which is
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
