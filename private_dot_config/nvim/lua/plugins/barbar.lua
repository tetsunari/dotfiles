return {
  "romgrk/barbar.nvim",
  dependencies = {
    'lewis6991/gitsigns.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  cmd = "BarbarEnable",
  event = "VeryLazy",
  opts = {
    animation = false,
    sidebar_filetypes = {
      ["no-neck-pain"] = {},
    },
  },
}
