vim.g.zig_fmt_parse_errors = 0
vim.g.zig_fmt_autosave = 0
vim.opt.pummaxwidth = 80
vim.cmd [[set completeopt+=menuone,noselect,popup]]
vim.keymap.set("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true, noremap = true })

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp', {}),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client:supports_method('textDocument/implementation') then
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = args.buf })
    end
    if client:supports_method('textDocument/references') then
      vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = args.buf })
    end
    if client:supports_method('textDocument/definition') then
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf })
    end
    if client:supports_method('textDocument/rename') then
      vim.keymap.set("n", "gn", vim.lsp.buf.rename, { buffer = args.buf })
    end
    -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
    if client:supports_method('textDocument/completion') then
      -- Optional: trigger autocompletion on EVERY keypress. May be slow!
      local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
      client.server_capabilities.completionProvider.triggerCharacters = chars
      vim.lsp.completion.enable(true, client.id, args.buf, {
        autotrigger = true,
      })
    end
  end,
})

vim.lsp.config("zls", {
  settings = {
    zls = {
      semantic_tokens = "partial",
    }
  }
})
vim.lsp.enable("zls")
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { "*.zig", "*.zon" },
  callback = function(ev)
    vim.lsp.buf.format()
  end
})

vim.lsp.config("lua_ls", {})
vim.lsp.enable("lua_ls")
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { "*.lua" },
  callback = function(ev)
    vim.lsp.buf.format()
  end
})

-- python
vim.lsp.config("pyright", {})
vim.lsp.enable("pyright")
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { "*.py" },
  callback = function(ev)
    vim.lsp.buf.format()
  end
})

-- typst
vim.lsp.config("tinymist", {
  settings = {
    formatterMode = "typstyle",
    exportPdf = "onType",
    semanticTokens = "partial",
  }
})
vim.lsp.enable("tinymist")
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { "*.typ" },
  callback = function(ev)
    vim.lsp.buf.format()
  end
})
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = { "*.typ" },
  callback = function(ev)
    local input = ev.file
    local base = vim.fn.fnamemodify(input, ":r") -- without extension
    local pdf_default = base .. ".pdf"
    local pdf_target = base .. ".typ.pdf"
    if vim.fn.filereadable(pdf_default) == 1 then
      vim.fn.rename(pdf_default, pdf_target)
    end
  end
})

-- c/c++
vim.lsp.config("clangd", {
  settings = {
    pattern = { "*.c", "*.cpp"},
  },
})
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { "*.c", "*.cpp" },
  callback = function(ev)
    vim.lsp.buf.format()
  end
})
vim.lsp.enable("clangd")

-- jinja2
-- vim.lsp.config("jinja_lsp", {
--   filetypes = { 'jinja' },
-- })
--
-- vim.lsp.enable("jinja-lsp")
--
-- vim.api.nvim_create_autocmd('BufWritePre', {
--   pattern = { "*.jinja", "*.jinja2", "*.j2" },
--   callback = function(ev)
--     vim.lsp.buf.format()
--   end
-- })
