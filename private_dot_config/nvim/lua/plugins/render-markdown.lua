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
  config = function(_, opts)
    require("render-markdown").setup(opts)
    vim.api.nvim_set_hl(0, "RenderMarkdownChecked", { fg = "#9ece6a" })
  end,
  opts = {
    latex = { enabled = false },
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
      unchecked = { icon = "󰝣 " },
      checked = {
        icon = "☑ ",
        highlight = "RenderMarkdownChecked",
        scope_highlight = "@markup.strikethrough",
      },
      custom = {
        todo = {
          raw = "[-]",
          rendered = "󰝣 ",
          highlight = "RenderMarkdownTodo",
          scope_highlight = "@markup.strikethrough",
        },
      },
    },
  },
}
