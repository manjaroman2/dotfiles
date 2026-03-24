vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.list = true
vim.opt.listchars = "eol:.,tab:>-,trail:~,extends:>,precedes:<"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes:1"
vim.opt.scrolloff = 8
vim.opt.showcmd = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.config/nvim/undodir"
vim.opt.undofile = true
vim.opt.clipboard = "unnamedplus"

vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.termguicolors = true

vim.opt.showmode = false

vim.cmd("colorscheme tokyonight")

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldcolumn = "2"

vim.opt.mouse = "a"

local settings_group = vim.api.nvim_create_augroup("user.settings", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = settings_group,
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = settings_group,
  desc = "Highlight text when yanking",
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = settings_group,
  pattern = "qf",
  callback = function()
    local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
    if wininfo.loclist == 1 then
      return
    end

    vim.cmd("wincmd L")
    vim.cmd("vertical resize 60")
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = settings_group,
  callback = function()
    for _, win in ipairs(vim.fn.getwininfo()) do
      if win.quickfix == 1 and win.loclist ~= 1 then
        vim.api.nvim_win_call(win.winid, function()
          vim.cmd("vertical resize 60")
        end)
      end
    end
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = settings_group,
  desc = "Return cursor to last position when reopening a file",
  pattern = "*",
  command = [[silent! normal! g`"zv]],
})
