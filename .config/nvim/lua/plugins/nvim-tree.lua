return {
  'nvim-tree/nvim-tree.lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    -- System open function
    local function system_open_node()
      local api = require('nvim-tree.api')
      local node = api.tree.get_node_under_cursor()
      if not node then return end
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

      -- Run asynchronously and detach immediately
      vim.system(cmd, { detach = true })
    end


    -- local preview_buf = nil
    -- local preview_win = nil
    -- local preview_active = false
    -- local preview_ft = nil -- track current filetype in preview buffer
    --
    -- local function preview_node(node)
    --   if not node or node.type == 'directory' then return end
    --   local path = node.absolute_path
    --   local tree_win = vim.api.nvim_get_current_win()
    --
    --   -- Create preview buffer if it doesn't exist
    --   if not preview_buf or not vim.api.nvim_buf_is_valid(preview_buf) then
    --     preview_buf = vim.api.nvim_create_buf(true, false) -- listed, scratch=false
    --   end
    --
    --   -- Create preview window if it doesn't exist
    --   if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
    --     vim.api.nvim_set_current_win(tree_win)
    --     vim.cmd('rightbelow vsplit')  -- open vertical split to the right
    --     preview_win = vim.api.nvim_get_current_win()
    --     vim.api.nvim_win_set_buf(preview_win, preview_buf)
    --     vim.w[preview_win].nvim_tree_preview = true
    --   end
    --
    --   -- Load file into preview buffer
    --   vim.api.nvim_win_set_buf(preview_win, preview_buf)
    --   vim.api.nvim_buf_set_name(preview_buf, path)
    --   vim.api.nvim_buf_call(preview_buf, function()
    --     vim.cmd('silent edit ' .. vim.fn.fnameescape(path))
    --   end)
    --
    --   -- Update filetype for Treesitter
    --   local ft = vim.filetype.match({ filename = path }) or vim.bo.filetype
    --   vim.api.nvim_buf_set_option(preview_buf, 'filetype', ft)
    --   -- Reattach Treesitter safely
    --   pcall(vim.treesitter.start, preview_buf, ft)
    --
    --   -- Keep focus in the tree window
    --   vim.api.nvim_set_current_win(tree_win)
    -- end

    require('nvim-tree').setup({
      open_on_tab = true,
      hijack_netrw = true,
      update_focused_file = { enable = false },
      view = {
        width = 30,
        side = "left",
        float = { enable = false },
      },
      actions = {
        open_file = {
          quit_on_open = true, -- closes tree only when opening a file, not directory
        },
      },
      on_attach = function(bufnr)
        local api = require('nvim-tree.api')

        api.config.mappings.default_on_attach(bufnr)

        local function opts(desc)
          return { desc = desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        vim.keymap.set('n', 'x', system_open_node, opts('System Open'))

        -- vim.keymap.set('n', 'P', function()
        --   preview_active = not preview_active  -- toggle preview mode
        --
        --   local node = api.tree.get_node_under_cursor()
        --
        --   if preview_active then
        --     -- Open preview for the current node
        --     preview_node(node)
        --   else
        --     -- Close the preview split if it exists
        --     if preview_win and vim.api.nvim_win_is_valid(preview_win) then
        --       vim.api.nvim_win_close(preview_win, true) -- true = force
        --       preview_win = nil
        --     end
        --   end
        -- end, opts('Toggle Preview Mode'))
        --
        -- vim.keymap.set('n', '<CR>', function()
        --   local node = api.tree.get_node_under_cursor()
        --   if not node then return end
        --
        --   -- Open file normally
        --   if node.type ~= 'directory' then
        --     api.node.open.edit()
        --   else
        --     api.node.open.edit() -- or expand dir
        --   end
        --
        --   if preview_win and vim.api.nvim_win_is_valid(preview_win) then
        --     -- Only close if more than one window exists
        --     if #vim.api.nvim_tabpage_list_wins(0) > 1 then
        --       vim.api.nvim_win_close(preview_win, true)
        --       preview_win = nil
        --     else
        --       -- Last window: do nothing
        --       -- preview_win remains valid but hidden naturally when tree quits
        --       preview_win = nil
        --     end
        --   end
        -- end, { buffer = bufnr, noremap = true, silent = true })
        --
        -- vim.api.nvim_create_autocmd('CursorMoved', {
        --   buffer = bufnr,
        --   callback = function()
        --     if not preview_active then return end
        --     local node = api.tree.get_node_under_cursor()
        --     preview_node(node)
        --   end,
        -- })

      end,
    })
  end,
}
