return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                typeCheckingMode = "basic", -- Options: "off", "basic", "strict"
                useLibraryCodeForTypes = true,
                autoImportCompletion = true,
              },
            },
          },
        },
      },
    },
  },
}
