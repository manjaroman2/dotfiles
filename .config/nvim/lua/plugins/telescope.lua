return {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    defaults = {
      mappings = {
        i = {
          ["<C-j>"] = require('telescope.actions').move_selection_next,
          ["<C-k>"] = require('telescope.actions').move_selection_previous,
        },
        n = {
          ["<C-j>"] = require('telescope.actions').move_selection_next,
          ["<C-k>"] = require('telescope.actions').move_selection_previous,
        },
      },
    },
    pickers = {
      buffers = {
        sort_mru = true,
        ignore_current_buffer = false,
        -- filter = function(buf)
        --   return vim.api.nvim_buf_get_option(buf, "buftype") == "quickfix"
        -- end,
      },
    },

  },
}
