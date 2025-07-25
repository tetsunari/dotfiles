return {
  "kylechui/nvim-surround",
  cond = true,
  event = "VeryLazy",
  opts = {
    surrounds = {
      ["/"] = {
        add = { "/", "/" },
        find = "()%/[^/\n]*%/()",
      },
      ["*"] = {
        add = { "*", "*" },
        find = "()%*[^*\n]*%*()",
      },
      ["_"] = {
        add = { "_", "_" },
        find = "()_[^_\n]*_()",
      },
      ["-"] = {
        add = { "-", "-" },
        find = "()-[^%-\n]*-()",
      },
      [":"] = {
        add = { ":", ":" },
        find = "():[^%:\n]*:()",
      },
    },
  },
}
