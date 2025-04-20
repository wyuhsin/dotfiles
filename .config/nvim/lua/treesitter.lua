require("nvim-treesitter.configs").setup({
	ensure_installed = { "lua", "go", "python", "javascript", "json", "html", "css", "bash", "yaml", "rust", "c" },
	highlight = { enable = true, additional_vim_regex_highlighting = false },
	indent = { enable = true },
})
