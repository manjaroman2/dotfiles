-- snippets
vim.snippet.expand = function(snippet)
  local luasnip = require("luasnip")
  luasnip.lsp_expand(snippet)
end

vim.g.zig_fmt_parse_errors = 0
vim.g.zig_fmt_autosave = 0
vim.opt.pummaxwidth = 80
vim.opt.completeopt:append({ "menuone", "noselect", "popup" })

local lsp_group = vim.api.nvim_create_augroup("user.lsp", { clear = true })

local function format_on_save(patterns)
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = lsp_group,
    pattern = patterns,
    callback = function()
      vim.lsp.buf.format()
    end,
  })
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_group,
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client:supports_method("textDocument/completion") then
      local chars = {}
      for i = 32, 126 do
        table.insert(chars, string.char(i))
      end
      client.server_capabilities.completionProvider.triggerCharacters = chars
      vim.lsp.completion.enable(true, client.id, args.buf, {
        autotrigger = true,
      })
    end
  end,
})

-- LSP config --

vim.lsp.config("zls", {
  settings = {
    zls = {
      semantic_tokens = "partial",
    },
  },
})
vim.lsp.enable("zls")
format_on_save({ "*.zig", "*.zon" })

vim.lsp.config("lua_ls", {})
vim.lsp.enable("lua_ls")
format_on_save({ "*.lua" })

-- python
vim.lsp.config("ruff", {
  init_options = {
    settings = {
      showSyntaxErrors = true,
    },
  },
})
vim.lsp.enable("ruff")
vim.lsp.config("zuban", {
  cmd = { vim.fn.expand("~/.local/share/zuban-env/bin/zuban"), "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", ".git" },
})
vim.lsp.enable("zuban")

-- typst
vim.lsp.config("tinymist", {
  settings = {
    formatterMode = "typstyle",
    exportPdf = "onType",
    semanticTokens = "partial",
  },
})
vim.lsp.enable("tinymist")
format_on_save({ "*.typ" })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = lsp_group,
  pattern = { "*.typ" },
  callback = function(ev)
    local input = ev.file
    local base = vim.fn.fnamemodify(input, ":r")
    local pdf_default = base .. ".pdf"
    local pdf_target = base .. ".typ.pdf"
    if vim.fn.filereadable(pdf_default) == 1 then
      vim.fn.rename(pdf_default, pdf_target)
    end
  end,
})

-- c/c++
vim.lsp.config("clangd", {})
format_on_save({ "*.c", "*.cpp", "*.hpp", "*.h" })
vim.lsp.enable("clangd")

-- go
vim.lsp.config("gopls", {})
vim.lsp.enable("gopls")
format_on_save({ "*.go" })

