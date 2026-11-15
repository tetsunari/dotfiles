return {
  "petertriho/nvim-scrollbar",
  branch = "v1", -- 既存のsetupオプションとscrollbar.handlers.searchを維持する
  event = "VeryLazy", -- nvim-hlslensの初期化にあわせる
  opts = {
    handle = {
      color = "gray",
    },
    marks = {
      Search = { color = "lime" },
      Error = { color = "red" },
      Warn = { color = "orange" },
      Info = { color = "cyan" },
      Hint = { color = "gray" },
      Misc = { color = "purple" },
    },
  },
}
