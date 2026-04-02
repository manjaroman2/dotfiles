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

local function make_osc52_clipboard()
  local osc52 = require('vim.ui.clipboard.osc52')
  local copy_plus = osc52.copy('+')
  local warned = false
  local cache = { {}, 'v' }

  local function copy(lines, regtype)
    cache = { vim.deepcopy(lines), regtype }
    copy_plus(lines, regtype)
  end

  local function paste()
    if #cache[1] == 0 and not warned then
      warned = true
      vim.notify(
        'Clipboard reads over OSC 52 are disabled here; use terminal paste instead.',
        vim.log.levels.INFO
      )
    end

    return { vim.deepcopy(cache[1]), cache[2] }
  end

  return {
    name = 'OSC 52',
    copy = {
      ['+'] = copy,
      ['*'] = copy,
    },
    paste = {
      ['+'] = paste,
      ['*'] = paste,
    },
  }
end

local is_ssh = vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT
local in_tmux = vim.env.TMUX
local has_graphical_clipboard = vim.env.WAYLAND_DISPLAY or vim.env.DISPLAY

-- Prefer tmux's clipboard bridge inside tmux, otherwise fall back to OSC 52
-- for remote/headless sessions where direct clipboard tools are unavailable.
if in_tmux and (is_ssh or not has_graphical_clipboard) then
  vim.g.clipboard = 'tmux'
elseif is_ssh or not has_graphical_clipboard then
  vim.g.clipboard = make_osc52_clipboard()
end

vim.opt.clipboard = 'unnamedplus'

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
