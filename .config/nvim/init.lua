vim.o.background = "dark"
vim.o.number = true
vim.o.showmode = true
vim.o.showcmd = true
vim.o.swapfile = false
vim.o.backup = false
vim.o.compatible = false
vim.o.errorbells = false
vim.o.wrap = true
vim.o.ignorecase = true
vim.o.mouse = ""
vim.o.scrolloff = 7
vim.o.fileencodings = "utf-8,gb18030,ucs-bom,gbk,gb2312,cp936"
vim.o.encoding = "utf-8"
vim.o.fileformat = "unix"
vim.o.expandtab = false
vim.o.tabstop = 8
vim.o.softtabstop = 8
vim.o.shiftwidth = 8
vim.o.shiftround = true
vim.o.smartindent = true
vim.o.backspace = "indent,eol,start"
vim.o.statusline = "%f col:%c"
vim.o.laststatus = 2
vim.o.makeprg = "mmake"

-- Mapping
vim.api.nvim_set_keymap("i", "jj", "<Esc>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>e', ':NvimTreeFocus<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ff', ':Telescope find_files<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>fr', ':Telescope oldfiles<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>fg', ':Telescope git_files<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>fk', ':Telescope live_grep<CR>', { noremap = true, silent = true })

-- Install lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- lazy.nvim
require("lazy").setup({
	"airblade/vim-rooter",
	"tpope/vim-fugitive",
	"neovim/nvim-lspconfig",
	"williamboman/mason.nvim",
	"williamboman/mason-lspconfig.nvim",
	"hrsh7th/nvim-cmp",
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"nvim-treesitter/nvim-treesitter",
	"projekt0n/github-nvim-theme",
	"kyazdani42/nvim-tree.lua",
	"nvim-lua/plenary.nvim",
	"nvim-telescope/telescope.nvim",
})

-- lsp style
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
	vim.lsp.handlers.hover, {
		max_width = 80,
		max_height = 20,
		wrap = true,
	}
)

vim.diagnostic.config({
	virtual_text = false,
	signs = true,
	underline = true,
	update_in_insert = true,
	float = {
		border = "single",
		source = "always",
		max_width = 80,
		max_height = 20,
		wrap = true,
	},
})

-- mason.nvim
require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = { "lua_ls", "gopls", "pyright", "ts_ls", "rust_analyzer", "clangd" }
})

local lspconfig = require("lspconfig")
local capabilities = require('cmp_nvim_lsp').default_capabilities()

local format_on_save = function(client, bufnr)
	if client.supports_method("textDocument/formatting") then
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format({ async = false })
			end
		})
	end
end

local on_attach = function(client, bufnr)
	format_on_save(client, bufnr)
	local opts = { buffer = bufnr, noremap = true, silent = true }

	vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
	vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
	vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
	vim.keymap.set("n", "[g", vim.diagnostic.goto_prev, opts)
	vim.keymap.set("n", "]g", vim.diagnostic.goto_next, opts)
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
end


local servers = { "lua_ls", "gopls", "pyright", "ts_ls", "rust_analyzer", "clangd" }
for _, server in ipairs(servers) do
	lspconfig[server].setup({
		capabilities = capabilities,
		on_attach = on_attach,
	})
end

-- nvim-cmp
local cmp = require("cmp")

cmp.setup({
	mapping = cmp.mapping.preset.insert({
		["<Tab>"] = cmp.mapping.select_next_item(),
		["<S-Tab>"] = cmp.mapping.select_prev_item(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "buffer" },
		{ name = "path" },
	}),
})

-- nvim-treesitter
require("nvim-treesitter.configs").setup({
	ensure_installed = { "lua", "go", "python", "javascript", "json", "html", "css", "bash", "yaml", "rust" },
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
	indent = {
		enable = true,
	},
})

-- theme
vim.cmd('colorscheme github_dark_default')

-- nvim-tree
-- vim.cmd('autocmd VimEnter * NvimTreeOpen')
-- vim.cmd('autocmd VimEnter * lua vim.cmd("wincmd p")')

local tree = require("nvim-tree")

tree.setup({
	open_on_tab = true,
	hijack_netrw = true,
	renderer = {
		icons = {
			show = {
				folder = false,
				file = false,
				folder_arrow = false,
				git = true
			},
			glyphs = {
				default = '',
				symlink = '',
				bookmark = '',
			},
		},
		indent_width = 4,
	},
	view = {
		width = 40
	},
})


-- telescope
local telescope = require('telescope')

telescope.setup({
	defaults = {
		mappings = {
			i = {
				["<C-u>"] = false,
				["<C-d>"] = false,
			},
		},
		file_ignore_patterns = { "*.git/*", "*.o", "*.pyc", "*.class", "*.tmp", "*.swp" },

	},
})
