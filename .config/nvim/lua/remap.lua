local M = {}

local map = vim.keymap.set
local remap_group = vim.api.nvim_create_augroup("user.remap", { clear = true })
local project = require("project")

local function telescope_picker(name)
  return function()
    require("telescope.builtin")[name]()
  end
end

local function flash_action(method)
  return function()
    require("flash")[method]()
  end
end

local function lsp_rename_and_save()
  vim.lsp.buf.rename()
  vim.cmd("wall")
end

local function toggle_quickfix()
  if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
    vim.cmd("cclose")
    return
  end

  vim.cmd("copen")
end

local function count_non_space_chars()
  local mode = vim.fn.visualmode()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local start_col = start_pos[3]
  local end_line = end_pos[2]
  local end_col = end_pos[3]
  local lines = vim.fn.getline(start_line, end_line)
  local text = {}

  if mode == "\22" then
    local s_col = math.min(start_col, end_col)
    local e_col = math.max(start_col, end_col)

    for _, line in ipairs(lines) do
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
end

local function toggle_nvim_tree()
  local api = require("nvim-tree.api")

  api.tree.toggle({ focus = true })

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(win, vim.o.columns)
  vim.api.nvim_win_set_height(win, vim.o.lines)
end

local function create_float_term(cmd, on_exit_callback)
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

local function find_file_upwards(filename)
  local curr = vim.fn.expand("%:p:h")

  while curr ~= "/" do
    if vim.fn.filereadable(curr .. "/" .. filename) == 1 then
      return curr
    end

    curr = vim.fn.fnamemodify(curr, ":h")
  end

  return nil
end

local function run_make()
  vim.cmd("write")
  project.apply_to_buffer(0)

  vim.cmd("cclose")
  vim.cmd("silent make")
  vim.cmd("redraw!")

  if #vim.fn.getqflist() > 0 then
    vim.cmd("copen")
  end
end

local function run_current_file()
  local filetype = vim.bo.filetype

  vim.cmd("write")

  local project_run = project.get_run_cmd(0)
  if project_run then
    create_float_term(project_run)
    return
  end

  if filetype == "zig" then
    local cmd = { "zig", "build", "--summary", "all", "run" }

    if vim.g.zig_make_args and vim.g.zig_make_args ~= "" then
      table.insert(cmd, "--")
      for arg in vim.g.zig_make_args:gmatch("%S+") do
        table.insert(cmd, arg)
      end
    end

    create_float_term(cmd)
    return
  end

  if filetype == "typst" then
    vim.cmd("make")

    local filepath = "./" .. vim.fn.expand("%:t:r") .. ".pdf"
    vim.defer_fn(function()
      vim.fn.jobstart({ "xdg-open", filepath }, { detach = true })
    end, 1000)
    return
  end

  if filetype == "python" then
    local filepath = vim.fn.expand("%:p")
    create_float_term({ "python", filepath }, function(code)
      print("Python script exited with code: " .. code)
    end)
    return
  end

  if filetype == "c" or filetype == "cpp" then
    if not find_file_upwards("CMakeLists.txt") then
      vim.notify("No CMakeLists.txt found", vim.log.levels.ERROR)
      vim.cmd("make")
      create_float_term({ "bash", "-c", "./" .. vim.fn.expand("%<") })
      return
    end

    create_float_term({
      "bash",
      "-c",
      "cmake --build build/Debug --target run --parallel",
    })
    return
  end

  if filetype == "go" then
    create_float_term({ "go", "run", "." })
    return
  end

  print("Unsupported filetype: " .. filetype .. " - try <leader>mm")
end

local qfwatch = require("qfwatch")
local watch_started = false
local zig_watch_buf

local function start_zig_watch()
  if vim.bo.filetype ~= "zig" then
    return
  end

  local qf_open = vim.iter(vim.fn.getwininfo()):any(function(wininfo)
    return wininfo.quickfix == 1
  end)

  if not qf_open then
    vim.cmd("copen")
  end

  if watch_started then
    qfwatch.stop()
  end

  if vim.fn.filereadable("last_compile_errors.txt") == 1 then
    qfwatch.start("last_compile_errors.txt")
    watch_started = true
  end

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
    "--watch",
  })

  vim.cmd("hide")
  print("Zig watch build started in buffer: " .. zig_watch_buf)
end

local function quickfix_step(command)
  return function()
    local qf_winid = vim.fn.win_getid()
    pcall(vim.cmd, command)
    vim.fn.win_gotoid(qf_winid)
  end
end

local function configure_c_family(makeprg)
  return function(args)
    vim.bo[args.buf].cindent = true
    vim.bo[args.buf].shiftwidth = 4
    vim.bo[args.buf].tabstop = 4
    vim.bo[args.buf].expandtab = true

    local root = project.get_root(args.buf)
    if root and project.root_has(root, "Makefile") then
      return
    end

    vim.api.nvim_set_option_value("makeprg", makeprg, { buf = args.buf, scope = "local" })
    vim.api.nvim_set_option_value("errorformat", "%f:%l:%c: %m", { buf = args.buf, scope = "local" })
  end
end

M.telescope_prompt_mappings = function(actions)
  return {
    i = {
      ["<C-j>"] = actions.move_selection_next,
      ["<C-k>"] = actions.move_selection_previous,
    },
    n = {
      ["<C-j>"] = actions.move_selection_next,
      ["<C-k>"] = actions.move_selection_previous,
    },
  }
end

M.treesitter_textobjects = {
  swap = {
    enable = true,
    swap_next = {
      ["<leader>a"] = "@parameter.inner",
    },
    swap_previous = {
      ["<leader>A"] = "@parameter.inner",
    },
  },
  select = {
    enable = true,
    lookahead = true,
    keymaps = {
      ["ip"] = "@parameter.inner",
      ["ap"] = "@parameter.outer",
    },
    selection_modes = {
      ["@parameter.outer"] = "v",
      ["@function.outer"] = "V",
      ["@class.outer"] = "<c-v>",
    },
    include_surrounding_whitespace = true,
  },
  move = {
    enable = true,
    set_jumps = true,
    goto_next_start = {
      ["]p"] = "@parameter.inner",
    },
    goto_previous_start = {
      ["[p"] = "@parameter.inner",
    },
    goto_next = {
      ["]d"] = "@conditional.outer",
    },
    goto_previous = {
      ["[d"] = "@conditional.outer",
    },
  },
}

M.nvim_tree_on_attach = function(bufnr)
  local api = require("nvim-tree.api")

  api.config.mappings.default_on_attach(bufnr)

  map("n", "x", M.system_open_node, {
    buffer = bufnr,
    desc = "System Open",
    noremap = true,
    nowait = true,
    silent = true,
  })
end

M.system_open_node = function()
  local api = require("nvim-tree.api")
  local node = api.tree.get_node_under_cursor()
  if not node then
    return
  end

  local path = node.absolute_path
  local cmd

  if vim.fn.has("macunix") == 1 then
    cmd = { "open", path }
  elseif vim.fn.has("unix") == 1 then
    cmd = { "xdg-open", path }
  elseif vim.fn.has("win32") == 1 then
    cmd = { "start", path }
  else
    vim.notify("Unsupported OS", vim.log.levels.ERROR)
    return
  end

  vim.system(cmd, { detach = true })
end

map("n", "<leader>f", telescope_picker("find_files"), { desc = "Find files" })
map("n", "<leader>g", telescope_picker("live_grep"), { desc = "Live grep" })
map("n", "<leader>bb", telescope_picker("buffers"), { desc = "Find buffers" })
map("n", "<leader>bd", "<cmd>bd<CR>", { desc = "Delete buffer" })
map("n", "<leader>bj", "<cmd>b#<CR>", { desc = "Jump to last buffer" })
map("n", "<leader>t", telescope_picker("planets"), { desc = "Browse planets" })

map({ "n", "x", "o" }, "s", flash_action("jump"), { desc = "Flash" })
-- map({ "n", "x", "o" }, "S", flash_action("treesitter"), { desc = "Flash Treesitter" })
map("o", "r", flash_action("remote"), { desc = "Remote Flash" })
map({ "o", "x" }, "R", flash_action("treesitter_search"), { desc = "Treesitter Search" })
map("c", "<C-s>", flash_action("toggle"), { desc = "Toggle Flash Search" })

map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })
map({ "n", "x" }, "d", '"_d', { desc = "Delete without yanking", noremap = true })
map("n", "<leader>q", toggle_quickfix, { desc = "Toggle quickfix" })
map("n", "[f", "zc", { desc = "Close fold under cursor" })
map("n", "]f", "zo", { desc = "Open fold under cursor" })
map("v", "<leader>cc", count_non_space_chars, { desc = "Count non-space chars", silent = true })
map("n", "<leader>e", toggle_nvim_tree, { desc = "Toggle file tree", noremap = true, silent = true })

map("i", "<C-k>", function()
  require("luasnip").expand_or_jump()
end, { desc = "Snippet expand or jump" })

map("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { desc = "Accept completion", expr = true, noremap = true })

map("n", "<leader>mm", run_make, { desc = "Make project", silent = true })
map("n", "<leader>mp", project.edit_makeprg, { desc = "Edit project makeprg", silent = true })
map("n", "<leader>mr", run_current_file, { desc = "Run current project/file", silent = true })
map("n", "<leader>mw", start_zig_watch, { desc = "Start Zig watch build", noremap = true, silent = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = remap_group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    local opts = { buffer = args.buf, silent = true }

    if client:supports_method("textDocument/implementation") then
      map("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
    end
    if client:supports_method("textDocument/references") then
      map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "List references" }))
    end
    if client:supports_method("textDocument/definition") then
      map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
    end
    if client:supports_method("textDocument/rename") then
      map("n", "gn", lsp_rename_and_save, vim.tbl_extend("force", opts, { desc = "Rename symbol and save" }))
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = remap_group,
  pattern = "qf",
  callback = function(event)
    local opts = { buffer = event.buf, noremap = true, silent = true }
    map("n", "j", quickfix_step("cnext"), opts)
    map("n", "k", quickfix_step("cprevious"), opts)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = remap_group,
  pattern = "zig",
  callback = function(args)
    vim.api.nvim_buf_create_user_command(args.buf, "Makeargs", function(opts)
      local arg_str = table.concat(opts.fargs, " ")
      vim.g.zig_make_args = arg_str
      print("zig_make_args set to: " .. arg_str)
    end, {
      nargs = "+",
      desc = "Set zig build args",
    })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = remap_group,
  pattern = "c",
  callback = configure_c_family("gcc % -o %<"),
})

vim.api.nvim_create_autocmd("FileType", {
  group = remap_group,
  pattern = "cpp",
  callback = configure_c_family("g++ % -o %<"),
})

project.setup()

return M
