return {
  "stevearc/conform.nvim",
  opts = {},
  config = function()
    local conform = require("conform")

    -- Function to determine formatters based on project files
    local function get_javascript_formatter()
      -- Check for biome.json in the project root
      local has_biome = vim.fn.filereadable(vim.fn.getcwd() .. "/biome.json") == 1

      -- Check for prettier config files
      local prettier_configs = {
        ".prettierrc",
        ".prettierrc.js",
        ".prettierrc.json",
        ".prettierrc.yml",
        ".prettierrc.yaml",
        "prettier.config.js",
        "prettier.config.cjs",
      }

      local has_prettier = false
      for _, config in ipairs(prettier_configs) do
        if vim.fn.filereadable(vim.fn.getcwd() .. "/" .. config) == 1 then
          has_prettier = true
          break
        end
      end

      -- Prioritize based on found config files
      if has_biome and not has_prettier then
        return { "biome-check" }
      elseif has_prettier and not has_biome then
        return { "prettierd" }
      else
        -- If both or none are found, prefer prettierd then biome as fallback
        return { "prettierd", "biome-check" }
      end
    end

    -- Get formatters when setting up
    local js_formatters = get_javascript_formatter()

    conform.setup({
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = js_formatters,
        json = js_formatters,
        jsonc = js_formatters,
        javascriptreact = js_formatters,
        typescript = js_formatters,
        typescriptreact = js_formatters,
        css = js_formatters,
        html = js_formatters,
        yaml = js_formatters,
        cpp = { "clang-format" },
        h = { "clang-format" },
        c = { "clang-format" },
        go = { "gofmt", "goimports" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    })

    -- Update formatters when changing directories
    vim.api.nvim_create_autocmd({ "DirChanged" }, {
      pattern = "*",
      callback = function()
        local new_js_formatters = get_javascript_formatter()
        local js_filetypes = {
          "javascript", "json", "jsonc", "javascriptreact",
          "typescript", "typescriptreact", "css", "html", "yaml"
        }

        for _, ft in ipairs(js_filetypes) do
          conform.formatters_by_ft[ft] = new_js_formatters
        end
      end,
    })
  end,
}
