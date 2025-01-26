return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    local mason = require("mason")
    local mason_lspconfig = require("mason-lspconfig")

    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      automatic_installaion = true,
      ensure_installed = {
        "lua_ls",
        "ts_ls",
        "eslint",
        "html",
        "cssls",
        "tailwindcss",
        "jsonls",
        "biome"
      }
    })
  end,
}
