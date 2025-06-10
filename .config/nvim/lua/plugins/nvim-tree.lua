return {
	"nvim-tree/nvim-tree.lua",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	cmd = { "NvimTreeToggle", "NvimTreeFocus" },
	config = function()
		require("nvim-tree").setup({
			open_on_tab = true,
			hijack_netrw = true,
			renderer = {
				icons = {
					show = {
						folder = false,
						file = false,
						folder_arrow = false,
						git = false,
					},
					glyphs = {
						default = '',
						symlink = '',
						bookmark = '',
					},
				},
				indent_width = 2,
			},
			view = {
				width = 50,
			},
			git = {
				enable = true,
				ignore = false,
			}
		})
	end,
}
