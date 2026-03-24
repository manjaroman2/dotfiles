return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = function()
    local actions = require("telescope.actions")
    local remap = require("remap")

    return {
      defaults = {
        mappings = remap.telescope_prompt_mappings(actions),
      },
      pickers = {
        buffers = {
          sort_mru = true,
          ignore_current_buffer = false,
        },
      },
    }
  end,
}
