require("nvim-tree").setup({
	open_on_tab = true,
	hijack_netrw = true,
	renderer = {
		icons = {
			show = { folder = false, file = false, folder_arrow = false, git = true },
			glyphs = { default = '', symlink = '', bookmark = '' },
		},
		indent_width = 4,
	},
	view = { width = 40 },
})
