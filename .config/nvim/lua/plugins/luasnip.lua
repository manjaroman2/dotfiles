return {
  "L3MON4D3/LuaSnip",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  config = function()
    -- require("easy-dotnet").setup()
    require("luasnip.loaders.from_vscode").lazy_load()
  end
}
