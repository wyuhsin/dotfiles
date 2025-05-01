require("nvim-tree").setup({
	open_on_tab = true,
	hijack_netrw = true,
	renderer = {
		icons = {
			show = { folder = false, file = false, folder_arrow = false, git = true },
			glyphs = { default = '', symlink = '', bookmark = '' },
		},
		indent_width = 2,
	},
	view = { width = 50 },
})
