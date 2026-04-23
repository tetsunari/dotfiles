return {
  "MeanderingProgrammer/render-markdown.nvim",
  cond = true,
  ft = { "markdown", "markdown.mdx", "snacks_dashboard", "snacks_notif" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<Space>sm", ":RenderMarkdown toggle<CR>", desc = "Toggle render-markdown" },
  },
  opts = {
    file_types = { "markdown", "snacks_dashboard", "snacks_notif" },
    render_modes = { "n", "c", "v" },
    heading = {
      sign = false,
      icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
      width = { "full", "full", "block", "block", "block", "block" },
    },
    code = {
      sign = false,
      width = "block",
      border = "thin",
    },
    win_options = {
      conceallevel = { default = 0, rendered = 2 },
      concealcursor = { default = "", rendered = "" },
    },
    html = {
      comment = { conceal = false },
    },
    checkbox = {
      unchecked = { icon = "󰄰 " },
      checked = {
        icon = "󰄳 ",
        scope_highlight = "@markup.strikethrough",
      },
      custom = {
        canceled = {
          raw = "[-]",
          rendered = "󱘹 ",
          scope_highlight = "@markup.strikethrough",
        },
      },
    },
  },
}
