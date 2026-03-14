-- snippets
vim.snippet.expand = function(snippet)
  local luasnip = require('luasnip')
  luasnip.lsp_expand(snippet)
end

vim.keymap.set("i", "<C-k>", function()
  require("luasnip").expand_or_jump()
end)

vim.g.zig_fmt_parse_errors = 0
vim.g.zig_fmt_autosave = 0
vim.opt.pummaxwidth = 80
vim.cmd [[set completeopt+=menuone,noselect,popup]]
vim.keymap.set("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true, noremap = true })

local function lsp_rename_and_save()
  vim.lsp.buf.rename()
  vim.cmd("wall") -- write all modified buffers
end

vim.keymap.set("n", "gn", lsp_rename_and_save)

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
      vim.keymap.set("n", "gn", lsp_rename_and_save, { buffer = args.buf })
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

-- Better quickfix navigation
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function(ev)
    local opts = { buffer = ev.buf, noremap = true, silent = true }
    vim.keymap.set("n", "j", function()
      local qf_winid = vim.fn.win_getid()  -- Save quickfix window ID
      -- vim.cmd("normal! j")
      -- vim.cmd(".cc")
      pcall(vim.cmd, "cnext")  -- Go to next quickfix item
      vim.fn.win_gotoid(qf_winid)  -- Return to saved quickfix window
    end, opts)
    vim.keymap.set("n", "k", function()
      local qf_winid = vim.fn.win_getid()  -- Save quickfix window ID
      -- vim.cmd("normal! k")
      -- vim.cmd(".cc")      
      pcall(vim.cmd, "cprevious")  -- Go to next quickfix item
      vim.fn.win_gotoid(qf_winid)  -- Return to saved quickfix window
    end, opts)
  end,
})

-- Also add BufEnter for when quickfix is re-opened
-- vim.api.nvim_create_autocmd("BufEnter", {
--   callback = function(ev)
--     if vim.bo[ev.buf].buftype == "quickfix" then
--       local opts = { buffer = ev.buf, noremap = true, silent = true }
--       vim.keymap.set("n", "j", function()
--         print("j mapping executed bufenter")
--         vim.cmd("normal! j")
--         vim.cmd(".cc")
--         vim.cmd("wincmd p")
--       end, opts)
--       vim.keymap.set("n", "k", function()
--         print("k mapping executed bufenter")
--         vim.cmd("normal! k")
--         vim.cmd(".cc")
--         vim.cmd("wincmd p")
--       end, opts)
--     end
--   end,
-- })

-- LSP config --

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
vim.lsp.config('ruff', {
  init_options = {
    settings = {
      showSyntaxErrors = true,
    }
  }
})
vim.lsp.enable('ruff')
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
  pattern = { "*.c", "*.cpp", "*.hpp", "*.h" },
  callback = function(ev)
    vim.lsp.buf.format()
  end
})
vim.lsp.enable("clangd")

-- go
vim.lsp.config("gopls", {
  -- settings = {
  -- }
})
vim.lsp.enable("gopls")
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { "*.go" },
  callback = function(ev)
    vim.lsp.buf.format()
  end
})

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



