local M = {}

local project_group = vim.api.nvim_create_augroup("user.project", { clear = true })

local root_markers = {
  ".git",
  ".nvim/makeprg.lua",
  "CMakeLists.txt",
  "Makefile",
  "build.zig",
  "go.mod",
  "Cargo.toml",
  "package.json",
  "pyproject.toml",
}

local function path_exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function is_buffer_file(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == ""
end

local function normalize_path(path)
  return vim.fs.normalize(path)
end

function M.find_root(start_dir)
  local dir = start_dir or vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.fn.getcwd()
  end

  dir = normalize_path(dir)

  while dir and dir ~= "/" do
    for _, marker in ipairs(root_markers) do
      if path_exists(dir .. "/" .. marker) then
        return dir
      end
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return nil
end

function M.makeprg_path(root)
  return root .. "/.nvim/makeprg.lua"
end

function M.get_root(bufnr)
  bufnr = bufnr or 0
  if not is_buffer_file(bufnr) then
    return nil
  end

  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    return nil
  end

  return M.find_root(vim.fn.fnamemodify(file, ":p:h"))
end

function M.root_has(root, filename)
  return root ~= nil and path_exists(root .. "/" .. filename)
end

local function template_lines_for(bufnr, root)
  local filetype = vim.bo[bufnr].filetype

  if not M.root_has(root, "Makefile") then
    if filetype == "c" then
      return {
        "return {",
        '  makeprg = "gcc % -o %<",',
        '  errorformat = "%f:%l:%c: %m",',
        '  run = "./%<",',
        "}",
      }
    end

    if filetype == "cpp" then
      return {
        "return {",
        '  makeprg = "g++ % -o %<",',
        '  errorformat = "%f:%l:%c: %m",',
        '  run = "./%<",',
        "}",
      }
    end
  end

  return {
    "return {",
    '  makeprg = "make",',
    '  -- errorformat = "%f:%l:%c: %m",',
    '  -- run = "./%<",',
    "}",
  }
end

local function load_project_settings(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  local ok, settings = pcall(dofile, path)
  if not ok then
    vim.notify("Failed to load project settings: " .. settings, vim.log.levels.ERROR)
    return nil
  end

  if type(settings) == "string" then
    return { makeprg = settings }
  end

  if type(settings) == "table" then
    return settings
  end

  vim.notify("Project settings must return a string or table: " .. path, vim.log.levels.ERROR)
  return nil
end

local function get_settings_for_path(file)
  if file == "" then
    return nil, nil
  end

  local root = M.find_root(vim.fn.fnamemodify(file, ":p:h"))
  if not root then
    return nil, nil
  end

  return load_project_settings(M.makeprg_path(root)), root
end

function M.get_settings(bufnr)
  bufnr = bufnr or 0
  if not is_buffer_file(bufnr) then
    return nil, nil
  end

  local file = vim.api.nvim_buf_get_name(bufnr)
  return get_settings_for_path(file)
end

local function expand_string(bufnr, value)
  return vim.api.nvim_buf_call(bufnr, function()
    return vim.fn.expandcmd(value)
  end)
end

local function resolve_value(bufnr, root, value)
  if type(value) == "function" then
    value = value({
      buf = bufnr,
      file = vim.api.nvim_buf_get_name(bufnr),
      filetype = vim.bo[bufnr].filetype,
      root = root,
    })
  end

  if type(value) == "string" then
    return expand_string(bufnr, value)
  end

  if type(value) == "table" then
    local resolved = {}
    for _, item in ipairs(value) do
      if type(item) ~= "string" then
        vim.notify("Project command tables must contain only strings", vim.log.levels.ERROR)
        return nil
      end
      table.insert(resolved, expand_string(bufnr, item))
    end
    return resolved
  end

  return nil
end

function M.apply_to_buffer(bufnr)
  bufnr = bufnr or 0
  if not is_buffer_file(bufnr) then
    return
  end

  local settings = M.get_settings(bufnr)
  if not settings then
    return
  end

  if type(settings.makeprg) == "string" and settings.makeprg ~= "" then
    vim.api.nvim_set_option_value("makeprg", settings.makeprg, { buf = bufnr, scope = "local" })
  end

  if type(settings.errorformat) == "string" and settings.errorformat ~= "" then
    vim.api.nvim_set_option_value("errorformat", settings.errorformat, { buf = bufnr, scope = "local" })
  end
end

function M.get_run_cmd(bufnr)
  bufnr = bufnr or 0
  local settings, root = M.get_settings(bufnr)
  if not settings or settings.run == nil then
    return nil
  end

  local cmd = resolve_value(bufnr, root, settings.run)
  if cmd == nil then
    vim.notify("Project run command must be a string, list of strings, or function", vim.log.levels.ERROR)
  end
  return cmd
end

local function reapply_root(root)
  local prefix = root .. "/"

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if is_buffer_file(bufnr) then
      local file = normalize_path(vim.api.nvim_buf_get_name(bufnr))
      if file ~= "" and (file == root or vim.startswith(file, prefix)) then
        M.apply_to_buffer(bufnr)
      end
    end
  end
end

function M.edit_makeprg()
  local current = vim.api.nvim_buf_get_name(0)
  local start_dir = current ~= "" and vim.fn.fnamemodify(current, ":p:h") or vim.fn.getcwd()
  local root = M.find_root(start_dir) or normalize_path(start_dir)
  local config_dir = root .. "/.nvim"
  local path = M.makeprg_path(root)

  if vim.fn.isdirectory(config_dir) ~= 1 then
    vim.fn.mkdir(config_dir, "p")
  end

  if vim.fn.filereadable(path) ~= 1 then
    vim.fn.writefile(template_lines_for(0, root), path)
  end

  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = project_group,
    callback = function(args)
      M.apply_to_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = project_group,
    pattern = "*/.nvim/makeprg.lua",
    callback = function(args)
      local root = M.find_root(vim.fn.fnamemodify(args.file, ":p:h"))
      if root then
        reapply_root(root)
      end
    end,
  })

  vim.api.nvim_create_user_command("ProjectMakeprg", function()
    M.edit_makeprg()
  end, {
    desc = "Edit the current project's makeprg config",
  })
end

return M
