local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
end

vim.opt.rtp:prepend(lazypath)

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
