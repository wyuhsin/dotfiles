vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  max_width = 80,
  max_height = 20,
  wrap = true,
})

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
