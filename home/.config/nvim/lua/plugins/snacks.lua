return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  -- stylua: ignore start
  keys = {
    -- lazygit
    { "<leader>g",  function() Snacks.lazygit() end,          silent = true, desc = "LazyGit" },
    { "<leader>gf", function() Snacks.lazygit.log_file() end, silent = true, desc = "LazyGit current file" },
    -- terminal
    { "<Space>i", function() Snacks.terminal.toggle() end, silent = true, desc = "Float terminal" },
    { "<Space>,", function() Snacks.terminal.toggle(nil, { win = { position = "bottom", height = 20 } }) end, silent = true, desc = "Terminal (small)" },
    { "<Space>.", function() Snacks.terminal.toggle(nil, { win = { position = "bottom", height = 35 } }) end, silent = true, desc = "Terminal (medium)" },
    {
      "<Space>t",
      function()
        local curdir = vim.bo.filetype == "oil" and require("oil").get_current_dir() or vim.fn.expand("%:p:h")
        Snacks.terminal.toggle(nil, { cwd = curdir })
      end,
      silent = true,
      desc = "Terminal (cwd)",
    },
    -- picker
    { "<leader>ff", function() Snacks.picker.files() end,        silent = true, desc = "Find files" },
    { "<leader>fg", function() Snacks.picker.grep() end,         silent = true, desc = "Grep" },
    { "<leader>fb", function() Snacks.picker.buffers() end,      silent = true, desc = "Find buffers" },
    { "<leader>fh", function() Snacks.picker.help() end,         silent = true, desc = "Find help tags" },
    { "<leader>gs", function() Snacks.picker.git_status() end,   silent = true, desc = "Git status" },
    { "<leader>gc", function() Snacks.picker.git_log() end,      silent = true, desc = "Git commits" },
    { "<leader>gb", function() Snacks.picker.git_branches() end, silent = true, desc = "Git branches" },
  },
  -- stylua: ignore end
  ---@type snacks.Config
  opts = {
    bigfile    = { enabled = true },
    dashboard  = { enabled = true },
    explorer   = { enabled = false },
    indent     = { enabled = true },
    input      = { enabled = true },
    lazygit    = { enabled = true },
    notifier   = { enabled = true, timeout = 3000 },
    picker = {
      enabled = true,
      sources = {
        files = { hidden = true },
        grep  = { hidden = true },
      },
      formatters = {
        file = {
          filename_first = true,
          truncate = 100,
        },
      },
      layout = {
        cycle = true,
        preset = "vertical",
        layout = {
          backdrop   = false,
          width      = 120,
          min_width  = 80,
          height     = 0.9,
          min_height = 30,
          box        = "vertical",
          border     = "rounded",
          title      = "{title} {live} {flags}",
          title_pos  = "center",
          { win = "preview", title = "{preview}", height = 0.5, border = "bottom" },
          { win = "input",   height = 1,           border = "bottom" },
          { win = "list",    border = "none" },
        },
      },
      win = {
        input = {
          keys = {
            ["<esc>"] = { "close",  mode = { "i", "n" } },
            ["<c-o>"] = { "qflist", mode = { "i", "n" } },
          },
        },
      },
    },
    quickfile    = { enabled = false },
    scope        = { enabled = false },
    scroll       = { enabled = false },
    statuscolumn = { enabled = true },
    terminal     = { enabled = true },
    words        = { enabled = true },
    styles = {
      notification = {},
    },
  },
}
