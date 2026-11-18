return {
  "Wansmer/treesj",
  cond = true,
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  keys = {
    {
      "<leader>ts",
      function()
        require("treesj").split()
      end,
      silent = true,
    },
    {
      "<leader>tj",
      function()
        require("treesj").join()
      end,
      silent = true,
    },
  },
  opts = {
    use_default_keymaps = false,
  },
}
