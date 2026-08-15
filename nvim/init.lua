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

-- kanso-ink, the same variant ghostty/config transcribes, so the editor and the
-- terminal come from one upstream. A real colorscheme rather than inheriting the
-- sixteen ANSI slots: a colorscheme addresses far more groups than sixteen.
--
-- termguicolors is set instead of left to autodetect, which reads COLORTERM —
-- that does not survive every ssh, and without it the theme drops to sixteen
-- colours silently rather than failing.
--
-- vim.pack is Neovim's own (0.12), so this adds a plugin without a plugin
-- manager. It clones on first start; nvim runs bare until it finishes.
vim.o.termguicolors = true
vim.pack.add({ "https://github.com/webhooked/kanso.nvim" })
vim.cmd.colorscheme("kanso-ink")

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

-- Icons are left at their defaults: they are already Nerd Font glyphs, and
-- ghostty/config loads the Mono build where each one is exactly one cell.
require("neo-tree").setup({
  close_if_last_window = true,
  window = { width = 32 },
  filesystem = {
    -- This is a dotfiles repo: hiding dotfiles would hide the whole tree.
    filtered_items = { hide_dotfiles = false, hide_gitignored = true },
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
  },
})

vim.keymap.set("n", "<leader>e", "<Cmd>Neotree toggle reveal<CR>", { desc = "Toggle file tree" })

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
    -- Same switches as FZF_CTRL_T_COMMAND in fish/config.fish.
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
