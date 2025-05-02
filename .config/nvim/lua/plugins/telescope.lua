return {
	"nvim-telescope/telescope.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	cmd = "Telescope",
	config = function()
		require("telescope").setup {
			defaults = {
				mappings = {
					i = {
						["<C-u>"] = false,
						["<C-d>"] = false,
					},
				},
				file_ignore_patterns = { "*.git/*", "*.o", "*.pyc", "*.class", "*.tmp", "*.swp" },
			},
		}
	end,
}

