return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local ok_alpha, alpha = pcall(require, "alpha")
    if not ok_alpha then
      return
    end

    local ok_theme, dashboard = pcall(require, "alpha.themes.dashboard")
    if not ok_theme then
      alpha.setup({})
      return
    end

    local function shortcut(sc)
      return string.format(" %s ", sc)
    end

    dashboard.section.header.val = { "Welcome" }

    dashboard.section.buttons.val = {
      dashboard.button("e", "New file", ":ene <BAR> startinsert <CR>"),
      dashboard.button("f", "Find file", ":Telescope find_files <CR>"),
      dashboard.button("r", "Recent", ":Telescope oldfiles <CR>"),
      dashboard.button("g", "Live grep", ":Telescope live_grep <CR>"),
      dashboard.button("c", "Config", ":e $MYVIMRC <CR>"),
      dashboard.button("q", "Quit", ":qa<CR>"),
    }

    dashboard.section.buttons.opts.hl_shortcut = "AlphaShortcut"
    for _, button in ipairs(dashboard.section.buttons.val) do
      button.opts.shortcut = shortcut(button.opts.shortcut)
    end

    local footer = ""
    local ok_lazy, lazy = pcall(require, "lazy")
    local version = vim.version()
    if ok_lazy then
      local stats = lazy.stats()
      footer = string.format(
        "%d plugins  •  NVIM v%d.%d.%d",
        stats.count,
        version.major,
        version.minor,
        version.patch
      )
    else
      footer = string.format(
        "NVIM v%d.%d.%d",
        version.major,
        version.minor,
        version.patch
      )
    end
    dashboard.section.footer.val = footer

    dashboard.section.footer.opts.hl = "AlphaFooter"
    dashboard.section.header.opts.hl = "AlphaHeader"

    dashboard.config.layout = {
      { type = "padding", val = 4 },
      dashboard.section.header,
      { type = "padding", val = 2 },
      dashboard.section.buttons,
      { type = "padding", val = 1 },
      dashboard.section.footer,
    }

    alpha.setup(dashboard.config)
  end,
}
