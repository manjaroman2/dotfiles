-- telescope
local telescope_builtin = require('telescope.builtin')
vim.keymap.set("n", "<leader>f", telescope_builtin.find_files, {})
vim.keymap.set("n", "<leader>g", telescope_builtin.live_grep, {})
vim.keymap.set("n", "<leader>bb", telescope_builtin.buffers, {})
vim.keymap.set("n", "<leader>t", telescope_builtin.planets, {})

-- move lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
-- search and replace under cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
-- netrw explorer
vim.keymap.set("n", "<leader>e", ":Explore<CR>")

-- all deletes blackhole
vim.keymap.set({ "n", "x" }, "d", '"_d', { noremap = true })
-- use system clipboard
vim.opt.clipboard = "unnamedplus"


vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlights text when yanking",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})


-- close buffer
vim.keymap.set("n", "<leader>bd", ":bd<CR>")

-- toggle quickfix list
vim.keymap.set("n", "<leader>q", ":cwindow<CR>")

-- make
vim.keymap.set("n", "<leader>mm",
  ":make<CR>:if len(getqflist()) > 0 | copen | endif<CR>",
  { silent = true }
)

-- zig: set make run options
vim.api.nvim_create_autocmd("FileType", {
  pattern = "zig",
  callback = function(args)
    vim.api.nvim_buf_create_user_command(
      args.buf,
      "Makeargs",
      function(opts)
        local arg_str = table.concat(opts.fargs, " ")
        vim.g.zig_make_args = table.concat(opts.fargs, " ")
        print("zig_make_args set to: " .. arg_str)
      end,
      {
        nargs = "+",
        desc = "Set global zig_make_args variable",
      }
    )
  end,
})
-- c: default options if no Makefile is present
vim.api.nvim_create_autocmd("FileType", {
    pattern = "c",
    callback = function()
        vim.opt.makeprg = "gcc % -o %<"
        vim.opt.errorformat = "%f:%l:%c: %m"
    end,
})

-- make run
vim.keymap.set("n", "<leader>mr", function()
  local ft = vim.bo.filetype
  if ft == "zig" then
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = 100,
      height = 20,
      row = 5,
      col = 12,
      style = "minimal",
    })
    local cmd = { "zig", "build", "--summary", "all", "run" }
    if vim.g.zig_make_args and vim.g.zig_make_args ~= "" then
      table.insert(cmd, "--")
      for arg in vim.g.zig_make_args:gmatch("%S+") do
        table.insert(cmd, arg)
      end
    end
    vim.fn.termopen(cmd, {
      on_exit = function(_, code, _)
        print("Process exited with code: " .. code)
        -- vim.api.nvim_win_close(win, true)
      end,
    })
    vim.api.nvim_set_current_buf(buf)
    vim.cmd("startinsert")
  elseif ft == "typst" then
    vim.cmd("make")
    local filename = vim.fn.expand("%:t:r") .. ".pdf"
    local filepath = "./" .. filename
    vim.defer_fn(function()
      vim.fn.jobstart({ "xdg-open", filepath }, {
        detach = true
      })
    end, 1000)
    return
  elseif ft == "python" then
    vim.cmd("write")
    local filepath = vim.fn.expand('%:p')
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = 100,
      height = 20,
      row = 5,
      col = 12,
      style = "minimal",
    })
    vim.api.nvim_set_current_buf(buf)

    local cmd = { "python", filepath }
    vim.fn.termopen(cmd, {
      on_exit = function(_, code, _)
        print("✅ Python script exited with code: " .. code)
        -- vim.api.nvim_win_close(win, true)
      end,
    })
    vim.cmd("startinsert")
  elseif ft == "c" then
    vim.cmd("write")
    local filepath = vim.fn.expand('%:p')
    local dir = vim.fn.expand('%:p:h')
    local output = dir .. "/" .. vim.fn.expand('%:t:r')
    local makeprg = vim.o.makeprg
    makeprg = makeprg:gsub("%%<", output)
    makeprg = makeprg:gsub("%%", filepath)
    local cmd = { "bash", "-c", makeprg .. " && " .. output }
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = 100,
      height = 20,
      row = 5,
      col = 12,
      style = "minimal",
    })
    vim.api.nvim_set_current_buf(buf)

    vim.fn.termopen(cmd, {
      on_exit = function(_, code, _)
        print("exited with code: " .. code)
        -- vim.api.nvim_win_close(win, true)
      end,
    })
    vim.cmd("startinsert")

  else
    print("Unsupported filetype: " .. ft .. " try <leader>mm")
  end
end)

-- make watch
qfwatch = require("qfwatch")
local watch_started = false
local zig_watch_buf = nil
vim.keymap.set("n", "<leader>mw", function()
  if vim.bo.filetype ~= "zig" then
    return
  end

  local qf_open = vim.iter(vim.fn.getwininfo()):any(function(wininf)
    return wininf.quickfix == 1
  end)
  if not qf_open then
    vim.cmd("copen")
  end

  if watch_started then
    qfwatch.stop()
  end

  if vim.fn.filereadable("last_compile_errors.txt") == 1 then
    qfwatch.start("last_compile_errors.txt")
    -- end
    watch_started = true
  end

  if zig_watch_buf and vim.api.nvim_buf_is_valid(zig_watch_buf) then
    vim.cmd("buffer " .. zig_watch_buf)
    return
  end
  zig_watch_buf = vim.api.nvim_create_buf(true, false) -- listed buffer
  vim.api.nvim_buf_set_name(zig_watch_buf, "Zig Watch Build")
  vim.cmd("belowright split")                          -- optional: create a temporary split to attach terminal
  vim.api.nvim_win_set_buf(0, zig_watch_buf)

  vim.fn.termopen({
    "zig",
    "build",
    "--build-runner",
    os.getenv("HOME") .. "/.config/nvim/extras/build_runner_0.15.1.zig",
    "-fincremental",
    "--watch"
  })
  vim.cmd("hide") -- buffer exists, running terminal, but not visible
  print("Zig watch build started in buffer: " .. zig_watch_buf)
end, { noremap = true, silent = true })


-- save cursor position
group_userconfig = vim.api.nvim_create_augroup("userconfig", {})
vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
  group = group_userconfig,
  desc = 'return cursor to where it was last time closing the file',
  pattern = '*',
  command = 'silent! normal! g`"zv',
})

vim.keymap.set('v', '<leader>cc', function()
  local mode       = vim.fn.visualmode() -- 'v', 'V', or '^V'
  local start_pos  = vim.fn.getpos("'<")
  local end_pos    = vim.fn.getpos("'>")

  local start_line = start_pos[2]
  local start_col  = start_pos[3]
  local end_line   = end_pos[2]
  local end_col    = end_pos[3]

  local lines      = vim.fn.getline(start_line, end_line)
  local text       = {}

  if mode == '\22' then -- visual block (Ctrl-V)
    -- iterate over lines and take only the selected columns
    for i, line in ipairs(lines) do
      local s_col = math.min(start_col, end_col)
      local e_col = math.max(start_col, end_col)
      table.insert(text, string.sub(line, s_col, e_col))
    end
  else
    -- character-wise or line-wise visual
    lines[1] = string.sub(lines[1], start_col)
    if #lines > 1 then
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
    text = lines
  end

  local joined = table.concat(text, "\n")
  local count = #joined:gsub("%s", "")
  print("Non-space characters: " .. count)
end, { silent = true })



-- ⌨️ Custom keybinds for folding
vim.keymap.set("n", "[f", "zc", { desc = "Close fold under cursor" })
vim.keymap.set("n", "]f", "zo", { desc = "Open fold under cursor" })

-- optional: toggle all folds with <leader>f
vim.keymap.set("n", "<leader>f", "zA", { desc = "Toggle fold under cursor" })


