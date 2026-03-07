vim.g.mapleader = " "

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

-- vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>o", "<C-o>")
vim.keymap.set("n", "<leader>i", "<C-i>")

vim.opt.guicursor = ""
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.hlsearch = false
vim.opt.hlsearch = false
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50
vim.opt.colorcolumn = "120"

vim.api.nvim_set_hl(0, "@lsp.type.comment.cpp", {})

-- Configure diagnostics
vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

local map = vim.keymap.set
local augroup = vim.api.nvim_create_augroup("erock.cfg", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

local yank_group = vim.api.nvim_create_augroup("HighlightYank", {})
autocmd("TextYankPost", {
	group = yank_group,
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 40,
		})
	end,
})

local function setup_lsp()
	-- Get blink.cmp capabilities for LSP
	local capabilities = require("blink.cmp").get_lsp_capabilities()

	vim.lsp.enable({
		"gopls",
		"lua_ls",
		"tsgo",
		"tailwindcss",
		"eslint",
		"biome",
		"oxlint",
	})

	-- Set capabilities for LSP
	vim.lsp.config("*", {
		capabilities = capabilities,
	})

	-- Configure gopls with GOEXPERIMENT=jsonv2
	vim.lsp.config("gopls", {
		cmd_env = {
			GOEXPERIMENT = "jsonv2",
		},
	})

	-- Custom ESLint config for monorepo support
	-- Finds ESLint config based on buffer context, not monorepo root
	local eslint_config_files = {
		".eslintrc",
		".eslintrc.js",
		".eslintrc.cjs",
		".eslintrc.yaml",
		".eslintrc.yml",
		".eslintrc.json",
		"eslint.config.js",
		"eslint.config.mjs",
		"eslint.config.cjs",
		"eslint.config.ts",
		"eslint.config.mts",
		"eslint.config.cts",
	}

	local flat_config_files = vim.tbl_filter(function(file)
		return file:match("config")
	end, eslint_config_files)

	vim.lsp.config("eslint", {
		root_dir = function(bufnr, on_dir)
			local filename = vim.api.nvim_buf_get_name(bufnr)

			-- Exclude deno projects
			if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
				return
			end

			-- Find the nearest ESLint config file starting from the buffer's directory
			local eslint_config = vim.fs.find(eslint_config_files, {
				path = filename,
				type = "file",
				upward = true,
			})[1]

			if eslint_config then
				on_dir(vim.fs.dirname(eslint_config))
			end
		end,
		settings = {
			validate = "on",
			packageManager = nil,
			useESLintClass = false,
			experimental = {
				useFlatConfig = false,
			},
			codeActionOnSave = {
				enable = false,
				mode = "all",
			},
			format = true,
			quiet = false,
			onIgnoredFiles = "off",
			rulesCustomizations = {},
			run = "onType",
			problems = {
				shortenToSingleLine = false,
			},
			nodePath = "",
			workingDirectory = { mode = "location" },
			codeAction = {
				disableRuleComment = {
					enable = true,
					location = "separateLine",
				},
				showDocumentation = {
					enable = true,
				},
			},
		},
		before_init = function(_, config)
			local root_dir = config.root_dir

			if root_dir then
				config.settings = config.settings or {}
				config.settings.workspaceFolder = {
					uri = root_dir,
					name = vim.fn.fnamemodify(root_dir, ":t"),
				}

				-- Detect if this root uses flat config (eslint.config.*)
				for _, file in ipairs(flat_config_files) do
					local config_path = root_dir .. "/" .. file
					if vim.uv.fs_stat(config_path) then
						config.settings.experimental = config.settings.experimental or {}
						config.settings.experimental.useFlatConfig = true
						break
					end
				end
			end
		end,
	})

	autocmd("LspAttach", {
		group = augroup,
		callback = function(ev)
			local bufopts = { noremap = true, silent = true, buffer = ev.buf }
			map("n", "gd", vim.lsp.buf.definition, bufopts)
			map("n", "[d", function()
				vim.diagnostic.jump({ count = -1, float = true })
			end, bufopts)
			map("n", "]d", function()
				vim.diagnostic.jump({ count = 1, float = true })
			end, bufopts)
			map("n", "<leader>e", function()
				vim.diagnostic.open_float({ border = "rounded", source = true })
			end, bufopts)
		end,
	})
end

vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/folke/snacks.nvim",
	"https://github.com/numToStr/Comment.nvim",
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/navarasu/onedark.nvim",
	{ src = "https://github.com/saghen/blink.cmp", version = "v1.8.0" },
	"https://github.com/github/copilot.vim",
	"https://github.com/rafamadriz/friendly-snippets",
})

require("onedark").setup({ transparent = true })
require("onedark").load()

require("nvim-web-devicons").setup({})
require("gitsigns").setup({
	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")

		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end

		map("n", "]c", function()
			if vim.wo.diff then
				vim.cmd.normal({ "]c", bang = true })
			else
				gitsigns.nav_hunk("next")
			end
		end, "Next git hunk")

		map("n", "[c", function()
			if vim.wo.diff then
				vim.cmd.normal({ "[c", bang = true })
			else
				gitsigns.nav_hunk("prev")
			end
		end, "Previous git hunk")

		map("n", "<leader>hs", gitsigns.stage_hunk, "Stage git hunk")
		map("n", "<leader>hr", gitsigns.reset_hunk, "Reset git hunk")
		map("n", "<leader>hp", gitsigns.preview_hunk, "Preview git hunk")
		map("n", "<leader>hb", gitsigns.blame_line, "Blame current line")
	end,
})

require("vim._extui").enable({})

require("snacks").setup({
	picker = { enabled = true },
})

-- Blink.cmp setup
require("blink.cmp").setup({
	keymap = {
		preset = "enter",
		["<C-k>"] = { "select_prev", "fallback" },
		["<C-j>"] = { "select_next", "fallback" },
	},

	appearance = {
		nerd_font_variant = "mono",
	},

	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},

	completion = {
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 500,
		},
	},

	signature = { enabled = true },

	-- Use prebuilt Rust binaries for better performance (auto-downloaded)
	fuzzy = {
		implementation = "prefer_rust_with_warning",
		prebuilt_binaries = {
			force_version = "v1.8.0", -- Force download of v1.8.0 prebuilt binary
		},
	},
})

setup_lsp()
require("mason").setup()
require("Comment").setup()

require("oil").setup({
	columns = { "icon" },
	keymaps = {
		["<C-h>"] = false,
		["<M-h>"] = "actions.select_split",
	},
	view_options = {
		show_hidden = true,
	},
})

-- Conform.nvim setup
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
		if parent == path then
			break
		end
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

	-- Check for oxfmt config files up the file tree
	local oxfmt_configs = {
		".oxfmtrc.json",
		".oxfmtrc.jsonc",
	}
	local has_oxfmt = find_config_file(oxfmt_configs, start_path) ~= nil

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
	if has_oxfmt then
		return { "oxfmt" }
	elseif has_biome and not has_prettier then
		return { "biome-check" }
	elseif has_prettier and not has_biome then
		return { "prettierd" }
	else
		-- If none are found, prefer prettierd then biome as fallback
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
		templ = { "templ" },
	},
	format_on_save = {
		timeout_ms = 500,
		lsp_fallback = true,
	},
})

-- Update formatters when changing directories or entering JS/TS files
autocmd({ "DirChanged" }, {
	pattern = "*",
	callback = function()
		local new_js_formatters = get_javascript_formatter()
		local js_filetypes = {
			"javascript",
			"json",
			"jsonc",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"css",
			"html",
			"yaml",
		}

		for _, ft in ipairs(js_filetypes) do
			conform.formatters_by_ft[ft] = new_js_formatters
		end
	end,
})

-- Update formatters when entering JS/TS files (to handle different project contexts)
autocmd({ "BufEnter" }, {
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
			yaml = true,
		}

		if js_filetypes[current_ft] then
			conform.formatters_by_ft[current_ft] = new_js_formatters
		end
	end,
})

require("nvim-treesitter").setup({
	install_dir = vim.fn.stdpath("data") .. "/site",
})

require("nvim-treesitter").install({
	"json",
	"go",
	"javascript",
	"typescript",
	"tsx",
	"jsx",
	"yaml",
	"html",
	"css",
	"markdown",
	"markdown_inline",
	"bash",
	"lua",
	"vim",
	"dockerfile",
	"gitignore",
})

autocmd("FileType", {
	group = augroup,
	pattern = "*",
	callback = function()
		local buf = vim.api.nvim_get_current_buf()
		pcall(vim.treesitter.start, buf)
	end,
})

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
vim.keymap.set("n", "<leader>pv", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- Snacks picker keybindings (ported from Telescope)
vim.keymap.set("n", "<leader>pf", function()
	Snacks.picker.files({ hidden = true })
end, { desc = "Find files" })

vim.keymap.set("n", "<leader>pl", function()
	Snacks.picker.grep()
end, { desc = "Live grep" })

vim.keymap.set("n", "<leader>pp", function()
	Snacks.picker.git_files()
end, { desc = "Git files" })

vim.keymap.set("n", "<leader>ps", function()
	local search = vim.fn.input("Grep > ")
	if search ~= "" then
		Snacks.picker.grep({ search = search })
	end
end, { desc = "Grep with input" })

vim.keymap.set("n", "<leader>pw", function()
	Snacks.picker.grep_word()
end, { desc = "Grep word under cursor" })

vim.keymap.set("n", "<leader>pW", function()
	local word = vim.fn.expand("<cWORD>")
	Snacks.picker.grep({ search = word })
end, { desc = "Grep WORD under cursor" })
