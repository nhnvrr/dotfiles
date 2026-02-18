return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
    config = function()
      local function use_dark_theme()
        if vim.fn.has("macunix") == 1 then
          local result = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null")
          return vim.v.shell_error == 0 and result:match("Dark") ~= nil
        end

        return vim.o.background == "dark"
      end

      local use_dark = use_dark_theme()
      local github_variant = use_dark and "github_dark" or "github_light"
      vim.o.background = use_dark and "dark" or "light"

      require("github-theme").setup({
        options = {
          compile_path = vim.fn.stdpath("cache") .. "/github-theme",
          compile_file_suffix = "_compiled",
          hide_end_of_buffer = true,
          hide_nc_statusline = true,
          transparent = false,
          terminal_colors = true,
          dim_inactive = false,
          module_default = true,
          styles = {
            comments = "italic",
            functions = "NONE",
            keywords = "NONE",
            variables = "NONE",
            conditionals = "NONE",
            constants = "NONE",
            numbers = "NONE",
            operators = "NONE",
            strings = "NONE",
            types = "NONE",
          },
          inverse = {
            match_paren = false,
            visual = false,
            search = false,
          },
          darken = {
            floats = true,
            sidebars = {
              enable = true,
              list = {},
            },
          },
          modules = {},
        },
        palettes = {},
        specs = {},
        groups = {},
      })
      vim.cmd.colorscheme(github_variant)
    end,
  },
  {
    "wtfox/jellybeans.nvim",
    name = "jellybeans",
    lazy = false,
    priority = 1000,
    config = function()
      require("jellybeans").setup({})
      -- vim.cmd("colorscheme jellybeans")
    end,
  },
}
