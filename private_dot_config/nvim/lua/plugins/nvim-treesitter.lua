return {
  "nvim-treesitter/nvim-treesitter",
  cond = true,
  event = { "BufNewFile", "BufRead" },
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup()

    -- iniファイルのみtreesitterハイライトを無効化
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "ini",
      callback = function(args)
        pcall(vim.treesitter.stop, args.buf)
      end,
    })

    -- 未インストールのパーサーを自動インストール
    local wanted = {
      "bash",
      "css",
      "diff",
      "dockerfile",
      "elixir",
      "gitignore",
      "gleam",
      "go",
      "html",
      "http",
      "javascript",
      "json",
      "kdl",
      "lua",
      "markdown",
      "markdown_inline",
      "python",
      "rust",
      "scss",
      "sql",
      "svelte",
      "toml",
      "tsx",
      "typescript",
      "vim",
      "vimdoc",
      "vue",
      "yaml",
    }
    local installed = require("nvim-treesitter.config").get_installed("parsers")
    local missing = vim.tbl_filter(function(p)
      return not vim.list_contains(installed, p)
    end, wanted)
    if #missing > 0 then
      vim.schedule(function()
        vim.cmd("TSInstall " .. table.concat(missing, " "))
      end)
    end
  end,
  init = function()
    -- zshファイルにbashパーサーを使用
    vim.treesitter.language.register("bash", "zsh")
  end,
}
