return {
  "stevearc/conform.nvim",
  opts = {},
  config = function()
    local conform = require("conform")

    -- Function to find config file up the directory tree
    local function find_config_file(config_files, start_path)
      start_path = start_path or vim.fn.getcwd()
      local path = start_path

      -- Handle empty path
      if path == "" then
        path = vim.fn.getcwd()
      end

      while path ~= "/" and path ~= "" do
        for _, config in ipairs(config_files) do
          local config_path = path .. "/" .. config
          if vim.fn.filereadable(config_path) == 1 then
            return config_path
          end
        end
        local parent = vim.fn.fnamemodify(path, ":h")
        if parent == path then break end
        path = parent
      end
      return nil
    end

    -- Function to determine formatters based on project files
    local function get_javascript_formatter()
      local current_file = vim.fn.expand("%:p")
      local start_path

      if current_file ~= "" then
        -- Use current file's directory
        start_path = vim.fn.fnamemodify(current_file, ":h")
      else
        -- No current file, start from current working directory and search up
        start_path = vim.fn.getcwd()
      end

      -- Check for biome.json up the file tree
      local biome_configs = { "biome.json", "biome.jsonc" }
      local has_biome = find_config_file(biome_configs, start_path) ~= nil

      -- Check for prettier config files up the file tree
      local prettier_configs = {
        ".prettierrc",
        ".prettierrc.js",
        ".prettierrc.json",
        ".prettierrc.yml",
        ".prettierrc.yaml",
        "prettier.config.js",
        "prettier.config.cjs",
      }

      local has_prettier = find_config_file(prettier_configs, start_path) ~= nil

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

    -- Update formatters when changing directories or entering JS/TS files
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

    -- Update formatters when entering JS/TS files (to handle different project contexts)
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
      pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.json", "*.jsonc", "*.css", "*.html", "*.yaml", "*.yml" },
      callback = function()
        local new_js_formatters = get_javascript_formatter()
        local current_ft = vim.bo.filetype
        local js_filetypes = {
          javascript = true,
          json = true,
          jsonc = true,
          javascriptreact = true,
          typescript = true,
          typescriptreact = true,
          css = true,
          html = true,
          yaml = true
        }

        if js_filetypes[current_ft] then
          conform.formatters_by_ft[current_ft] = new_js_formatters
        end
      end,
    })
  end,
}

