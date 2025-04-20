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
