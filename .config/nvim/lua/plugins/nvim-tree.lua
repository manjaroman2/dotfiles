return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("nvim-tree").setup({
      git = {
        ignore = false,
      },
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
          quit_on_open = true,
        },
      },
      on_attach = require("remap").nvim_tree_on_attach,
    })
  end
}
