return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
  {
    "folke/flash.nvim",
    cond = true,
    event = "VeryLazy",
    opts = {
      label = {
        distance = false,
      },
      modes = {
        search = {
          enabled = false,
        },
        char = {
          enabled = false,
        },
      },
    },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "R",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#efef33", bold = true })
          vim.api.nvim_set_hl(0, "FlashMatch", { fg = "#3d59a1", bold = true })
        end,
      })
    end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      "s1n7ax/nvim-window-picker",
    },
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
      { "<leader>o", "<cmd>Neotree focus<cr>", desc = "Focus Neo-tree" },
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        enable_git_status = true,
        enable_diagnostics = true,
        sources = {
          "filesystem",
        },
        filesystem = {
          follow_current_file = {
            enabled = true,
            leave_dirs_open = true,
          },
          use_libuv_file_watcher = true, -- パフォーマンス向上
          filtered_items = {
            visible = false,
            hide_dotfiles = false,
            hide_gitignored = false,
            -- hide_by_name = {
            --     "node_modules",
            -- },
            never_show = {
              ".git",
              ".DS_Store",
            },
          },
        },
        window = {
          width = 30,
          mappings = {
            ["<cr>"] = "open",
            ["S"] = "open_split",
            ["s"] = "",
            ["V"] = "open_vsplit",
            ["v"] = "",
          },
        },
      })
    end,
  }
}
