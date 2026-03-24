return {
  "GustavEikaas/easy-dotnet.nvim",
  cmd = "Dotnet",
  ft = { "cs", "csproj", "fs", "fsproj", "sln" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("easy-dotnet").setup()
  end,
}
