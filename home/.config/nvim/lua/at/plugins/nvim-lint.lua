return {
	"mfussenegger/nvim-lint",
	config = function()
		local lint = require("lint")
		-- No explicit linters needed yet
		lint.linters_by_ft = {}
		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			callback = function()
				require("lint").try_lint()
			end,
		})
	end,
}
