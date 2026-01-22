return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
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

    alpha.setup(dashboard.config)
  end,
}
