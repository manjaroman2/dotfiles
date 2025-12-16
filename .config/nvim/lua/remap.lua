-- ============================================================================
-- UTILITIES
-- ============================================================================

local M = {}

-- Create a floating terminal window
M.create_float_term = function(cmd, on_exit_callback)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 100,
    height = 20,
    row = 5,
    col = 12,
    style = "minimal",
    border = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
  })
  
  vim.api.nvim_set_current_buf(buf)
  vim.fn.termopen(cmd, {
    on_exit = function(_, code, _)
      if on_exit_callback then
        on_exit_callback(code)
      else
        print("Process exited with code: " .. code)
      end
    end,
  })
  vim.cmd("startinsert")
  
  return buf, win
end

-- Find file in current or parent directories
M.find_file_upwards = function(filename)
  local dir = vim.fn.expand('%:p:h')
  local curr = dir
  
  while curr ~= "/" do
    if vim.fn.filereadable(curr .. "/" .. filename) == 1 then
      return curr
    end
    curr = vim.fn.fnamemodify(curr, ":h")
  end
  
  return nil
end

-- ============================================================================
-- TELESCOPE
-- ============================================================================

local telescope_builtin = require('telescope.builtin')
vim.keymap.set("n", "<leader>f", telescope_builtin.find_files, {})
vim.keymap.set("n", "<leader>g", telescope_builtin.live_grep, {})
vim.keymap.set("n", "<leader>bb", telescope_builtin.buffers, {})
vim.keymap.set("n", "<leader>t", telescope_builtin.planets, {})

-- ============================================================================
-- GENERAL KEYMAPS
-- ============================================================================

-- Move lines in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Search and replace word under cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- All deletes go to blackhole register
vim.keymap.set({ "n", "x" }, "d", '"_d', { noremap = true })

-- Close buffer
vim.keymap.set("n", "<leader>bd", ":bd<CR>")

-- Toggle quickfix list
-- vim.keymap.set("n", "<leader>q", ":cwindow<CR>")
vim.keymap.set("n", "<leader>q", function()
  if vim.fn.getqflist({winid = 0}).winid ~= 0 then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end)

-- Folding keybinds
vim.keymap.set("n", "[f", "zc", { desc = "Close fold under cursor" })
vim.keymap.set("n", "]f", "zo", { desc = "Open fold under cursor" })
-- vim.keymap.set("n", "<leader>f", "zA", { desc = "Toggle fold under cursor" })

-- Character count in visual selection
vim.keymap.set('v', '<leader>cc', function()
  local mode = vim.fn.visualmode()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local start_col = start_pos[3]
  local end_line = end_pos[2]
  local end_col = end_pos[3]
  local lines = vim.fn.getline(start_line, end_line)
  local text = {}
  
  if mode == '\22' then -- visual block (Ctrl-V)
    for i, line in ipairs(lines) do
      local s_col = math.min(start_col, end_col)
      local e_col = math.max(start_col, end_col)
      table.insert(text, string.sub(line, s_col, e_col))
    end
  else
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

-- ============================================================================
-- NVIM-TREE
-- ============================================================================

vim.keymap.set("n", "<leader>e", function()
  local nvim_tree_api = require('nvim-tree.api')
  nvim_tree_api.tree.toggle({ focus = true })
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(win, vim.o.columns)
  vim.api.nvim_win_set_height(win, vim.o.lines)
end, { noremap = true, silent = true })

-- ============================================================================
-- CLIPBOARD & YANKING
-- ============================================================================

vim.opt.clipboard = "unnamedplus"

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlights text when yanking",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- ============================================================================
-- QUICKFIX CONFIGURATION
-- ============================================================================

-- Quickfix always on the right
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    if vim.fn.getwininfo(vim.fn.win_getid())[1].loclist ~= 1 then
      vim.cmd("wincmd L")
      vim.cmd("vertical resize 60")
    end
  end,
})

-- Quickfix responds to resize
vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    for _, win in ipairs(vim.fn.getwininfo()) do
      if win.quickfix == 1 and win.loclist ~= 1 then
        vim.api.nvim_set_current_win(win.winid)
        vim.cmd("vertical resize 60")
      end
    end
  end,
})

-- ============================================================================
-- MAKE COMMAND
-- ============================================================================

vim.keymap.set("n", "<leader>mm", function()
  local ft = vim.bo.filetype
  
  -- C/C++ custom make with CMake
  if ft == "c" or ft == "cpp" then
    vim.cmd("write")
    local cmake_dir = M.find_file_upwards("CMakeLists.txt")
    
    if cmake_dir then
      vim.opt.makeprg = "cmake --build build/Debug --parallel"
    end
  end
  
  vim.cmd("cclose")  -- Close first
  vim.cmd("silent make")
  vim.cmd("redraw!")
  if #vim.fn.getqflist() > 0 then
    vim.cmd("copen")  -- Then reopen
  end
end, { silent = true })

-- ============================================================================
-- FILETYPE-SPECIFIC CONFIGURATION
-- ============================================================================

-- Zig configuration
vim.api.nvim_create_autocmd("FileType", {
  pattern = "zig",
  callback = function(args)
    vim.api.nvim_buf_create_user_command(
      args.buf,
      "Makeargs",
      function(opts)
        local arg_str = table.concat(opts.fargs, " ")
        vim.g.zig_make_args = arg_str
        print("zig_make_args set to: " .. arg_str)
      end,
      {
        nargs = "+",
        desc = "Set global zig_make_args variable",
      }
    )
  end,
})

-- C configuration
vim.api.nvim_create_autocmd("FileType", {
  pattern = "c",
  callback = function()
    vim.opt.makeprg = "gcc % -o %<"
    vim.opt.errorformat = "%f:%l:%c: %m"
    vim.bo.cindent = true
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.expandtab = true
  end,
})

-- C++ configuration
vim.api.nvim_create_autocmd("FileType", {
  pattern = "cpp",
  callback = function()
    vim.opt.makeprg = "g++ % -o %<"
    vim.opt.errorformat = "%f:%l:%c: %m"
    vim.bo.cindent = true
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.expandtab = true
  end,
})

-- ============================================================================
-- MAKE RUN (<leader>mr)
-- ============================================================================

vim.keymap.set("n", "<leader>mr", function()
  local ft = vim.bo.filetype
  
  -- ===== ZIG =====
  if ft == "zig" then
    local cmd = { "zig", "build", "--summary", "all", "run" }
    
    if vim.g.zig_make_args and vim.g.zig_make_args ~= "" then
      table.insert(cmd, "--")
      for arg in vim.g.zig_make_args:gmatch("%S+") do
        table.insert(cmd, arg)
      end
    end
    
    M.create_float_term(cmd)
  
  -- ===== TYPST =====
  elseif ft == "typst" then
    vim.cmd("make")
    local filename = vim.fn.expand("%:t:r") .. ".pdf"
    local filepath = "./" .. filename
    
    vim.defer_fn(function()
      vim.fn.jobstart({ "xdg-open", filepath }, { detach = true })
    end, 1000)
  
  -- ===== PYTHON =====
  elseif ft == "python" then
    vim.cmd("write")
    local filepath = vim.fn.expand('%:p')
    M.create_float_term({ "python", filepath }, function(code)
      print("✅ Python script exited with code: " .. code)
    end)
  
  -- ===== C/C++ =====
  elseif ft == "c" or ft == "cpp" then
      vim.cmd("write")

      local cmake_dir = M.find_file_upwards("CMakeLists.txt")
      if not cmake_dir then
        vim.notify("No CMakeLists.txt found", vim.log.levels.ERROR)
        return
      end

      local cmd = {
        "bash",
        "-c",
        "cd " .. cmake_dir .. " && " ..
        "([ -d build ] || (mkdir -p build && cmake -S . -B build)) && " ..
        "cmake --build build/Release --target run --parallel"
      }

      M.create_float_term(cmd)


  else
    print("Unsupported filetype: " .. ft .. " - try <leader>mm")
  end
end)


-- ============================================================================
-- MAKE WATCH (<leader>mw) - ZIG ONLY
-- ============================================================================

local qfwatch = require("qfwatch")
local watch_started = false
local zig_watch_buf = nil

vim.keymap.set("n", "<leader>mw", function()
  if vim.bo.filetype ~= "zig" then
    return
  end
  
  -- Open quickfix if not already open
  local qf_open = vim.iter(vim.fn.getwininfo()):any(function(wininf)
    return wininf.quickfix == 1
  end)
  
  if not qf_open then
    vim.cmd("copen")
  end
  
  -- Start watching compile errors
  if watch_started then
    qfwatch.stop()
  end
  
  if vim.fn.filereadable("last_compile_errors.txt") == 1 then
    qfwatch.start("last_compile_errors.txt")
    watch_started = true
  end
  
  -- Create or switch to zig watch buffer
  if zig_watch_buf and vim.api.nvim_buf_is_valid(zig_watch_buf) then
    vim.cmd("buffer " .. zig_watch_buf)
    return
  end
  
  zig_watch_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(zig_watch_buf, "Zig Watch Build")
  vim.cmd("belowright split")
  vim.api.nvim_win_set_buf(0, zig_watch_buf)
  
  vim.fn.termopen({
    "zig",
    "build",
    "--build-runner",
    os.getenv("HOME") .. "/.config/nvim/extras/build_runner_0.15.1.zig",
    "-fincremental",
    "--watch"
  })
  
  vim.cmd("hide")
  print("Zig watch build started in buffer: " .. zig_watch_buf)
end, { noremap = true, silent = true })

-- ============================================================================
-- MISC AUTOCMDS
-- ============================================================================

-- Save cursor position
local group_userconfig = vim.api.nvim_create_augroup("userconfig", {})

vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
  group = group_userconfig,
  desc = 'Return cursor to where it was last time closing the file',
  pattern = '*',
  command = 'silent! normal! g`"zv',
})
