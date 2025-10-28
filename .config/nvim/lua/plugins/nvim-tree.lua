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

      if vim.fn.has("macunix") == 1 then
        vim.fn.system({"open", path})
      elseif vim.fn.has("unix") == 1 then
        vim.fn.system({"xdg-open", path})
      elseif vim.fn.has("win32") == 1 then
        vim.fn.system({"start", path})
      end
    end

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

        -- Keep all default keymaps
        api.config.mappings.default_on_attach(bufnr)

        -- Custom keymaps
        local function opts(desc)
          return { desc = desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        -- Map 'x' to system open
        vim.keymap.set('n', 'x', system_open_node, opts('System Open'))
      end,
    })
  end,
}
