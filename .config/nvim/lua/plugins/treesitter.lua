return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
  branch = "master",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local remap = require("remap")

    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "c",
        "cpp",
        "query",
        "html",
        "css",
      },
      sync_install = false,
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      textobjects = remap.treesitter_textobjects,
    })
  end,
}
