return {
	"stevearc/conform.nvim",
	opts = {},
	config = function()
		local conform = require("conform")
		conform.setup({
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettierd" },
				json = { "prettierd" },
				jsonc = { "prettierd" },
				javascriptreact = { "prettierd" },
				typescript = { "prettierd" },
				typescriptreact = { "prettierd" },
				css = { "prettierd" },
				html = { "prettierd" },
				yaml = { "prettierd" },
				-- javascript = { "biome" },
				-- json = { "biome" },
				-- jsonc = { "biome" },
				-- javascriptreact = { "biome" },
				-- typescript = { "biome" },
				-- typescriptreact = { "biome" },
				-- css = { "biome" },
				-- html = { "biome" },
				-- yaml = { "biome" },
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
	end,
}
