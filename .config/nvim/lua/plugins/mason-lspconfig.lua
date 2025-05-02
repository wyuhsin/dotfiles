return {
	"williamboman/mason-lspconfig.nvim",
	dependencies = {
		"williamboman/mason.nvim",
		"neovim/nvim-lspconfig",
	},
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls", "gopls", "pyright", "tsserver", "rust_analyzer", "clangd"
			},
			automatic_installation = true,
		})
	end,
}

