vim.api.nvim_set_keymap("i", "jj", "<Esc>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ff', ':Telescope find_files<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>fr', ':Telescope oldfiles<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>fg', ':Telescope git_files<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>fk', ':Telescope live_grep<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>fs', function()
	require('telescope.builtin').lsp_document_symbols({
		layout_config = {
			width = 0.8
		},
		layout_strategy = 'horizontal'
	})
end, { noremap = true, silent = true })
