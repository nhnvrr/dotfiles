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

-- github_dark_dimmed, the same variant alacritty.toml paints, keeps
-- the editor and terminal aligned. A real colorscheme rather than inheriting the
-- sixteen ANSI slots: a colorscheme addresses far more groups than sixteen.
--
-- termguicolors is set instead of left to autodetect, which reads COLORTERM —
-- that does not survive every ssh, and without it the theme drops to sixteen
-- colours silently rather than failing.
--
-- vim.pack is Neovim's own (0.12), so this adds a plugin without a plugin
-- manager. It clones on first start; nvim runs bare until it finishes.
--
-- Major pinned, same reason as neo-tree below: this plugin went through a
-- breaking 0.0.x to v1 rewrite that renamed every colorscheme.
vim.o.termguicolors = true
vim.pack.add({
  { src = "https://github.com/projekt0n/github-nvim-theme", version = vim.version.range("1") },
})
-- setup() has to run before the colorscheme command: it only stores options,
-- and the highlights are built when the scheme loads.
--
-- transparent drops the Normal background so the terminal shows through. The
-- theme's own background is then gone, so what you actually see is whatever
-- alacritty.toml paints.
require("github-theme").setup({
  options = {
    transparent = true,
    styles = {
      comments = "NONE",
      conditionals = "NONE",
      constants = "NONE",
      functions = "NONE",
      keywords = "NONE",
      numbers = "NONE",
      operators = "NONE",
      strings = "NONE",
      types = "NONE",
      variables = "NONE",
    },
  },
})
vim.cmd.colorscheme("github_dark")

-- styles above only reach the syntax groups the theme exposes; bold survives in
-- Title, diagnostics, the popup menu and every plugin group. This sweeps all of
-- them, and re-runs on ColorScheme because loading a scheme rebuilds the table.
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
-- define their groups after this point, and fzf-lua defines some of its own on
-- first open. This pass runs once the whole config has been read.
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
-- and alacritty.toml loads the Mono build where each one is one cell.
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

-- The auto theme is derived from the loaded colorscheme, so it arrives with
-- github_dark's own backgrounds and a bold mode section. Both are stripped
-- here rather than after setup(): lualine copies the table it is given and
-- rebuilds these groups on ColorScheme, which would undo a later override.
local lualine_theme = require("lualine.themes.auto")
for _, mode in pairs(lualine_theme) do
  for _, section in pairs(mode) do
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
  extensions = { "neo-tree", "fzf" },
})

-- fzf-lua and not telescope: it shells out to the same fzf binary the shell
-- already uses, so file search matches the same way in both places and there is
-- no second fuzzy engine to build. devicons is already here for neo-tree.
--
-- live_grep needs ripgrep, which is why Brewfile declares it: every rg on this
-- machine otherwise belongs to some editor extension, not to the profile.
vim.pack.add({ "https://github.com/ibhagwan/fzf-lua" })

require("fzf-lua").setup({
  winopts = {
    height = 0.85,
    width = 0.85,
    border = "rounded",
    preview = { layout = "vertical", vertical = "down:45%" },
  },
  files = {
    -- Same switches as FZF_CTRL_T_COMMAND in zsh/zshrc.
    fd_opts = "--type f --hidden --follow --exclude .git",
  },
})

local fzf = require("fzf-lua")

vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Find file" })
vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Grep in project" })
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "Find buffer" })
vim.keymap.set("n", "<leader>fh", fzf.helptags, { desc = "Find help tag" })
vim.keymap.set("n", "<leader>/", fzf.blines, { desc = "Grep in current file" })

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
