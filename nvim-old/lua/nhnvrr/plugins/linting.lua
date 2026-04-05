return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      python = { "pylint" },
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      svelte = { "eslint_d" },
      terraform = { "tflint" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    local function file_in_cwd(file_name)
      return vim.fs.find(file_name, {
        upward = true,
        stop = vim.loop.cwd():match("(.+)/"),
        path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
        type = "file",
      })[1]
    end

    local function linter_in_linters(linters, linter_name)
      for k, v in pairs(linters) do
        if v == linter_name then
          return true
        end
      end
      return false
    end

    local function eslint_config_present()
      return file_in_cwd("eslint.config.js")
          or file_in_cwd(".eslintrc.cjs")
          or file_in_cwd(".eslintrc.js")
          or file_in_cwd(".eslintrc.json")
          or file_in_cwd(".eslintrc")
    end

    local function find_cmd(bin)
      local buf_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
      local local_cmd = vim.fs.find("node_modules/.bin/" .. bin, { upward = true, path = buf_dir, type = "file" })[1]
      if local_cmd then
        return local_cmd
      end
      if vim.fn.executable(bin) == 1 then
        return bin
      end
    end

    local function try_linting()
      local linters = lint.linters_by_ft[vim.bo.filetype]

      if not linters then
        return
      end

      if linter_in_linters(linters, "eslint_d") then
        if not eslint_config_present() then
          return
        end

        local eslint_d_cmd = find_cmd("eslint_d")
        if eslint_d_cmd then
          lint.linters.eslint_d.cmd = eslint_d_cmd
        else
          local eslint_cmd = find_cmd("eslint")
          if eslint_cmd then
            lint.linters.eslint.cmd = eslint_cmd
            linters = vim.tbl_filter(function(linter)
              return linter ~= "eslint_d"
            end, linters)
            table.insert(linters, "eslint")
          else
            vim.notify("nvim-lint: eslint_d/eslint not found", vim.log.levels.WARN)
            return
          end
        end
      end

      lint.try_lint(linters)
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        try_linting()
      end,
    })

    vim.keymap.set("n", "<leader>l", function()
      try_linting()
    end, { desc = "Trigger linting for current file" })
  end,
}
