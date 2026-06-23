return {
  "epwalsh/obsidian.nvim",
  version = "*",  -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  cmd = {
    "ObsidianToday",
    "ObsidianYesterday",
    "ObsidianTomorrow",
    "ObsidianNew",
    "ObsidianOpen",
    "ObsidianSearch",
    "ObsidianQuickSwitch",
    "ObsidianFollowLink",
    "ObsidianBacklinks",
    "ObsidianTags",
    "ObsidianTemplate",
    "ObsidianMTG",
    "ObsidianReview",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "vault",
        path = "~/vault",
      },
    },

    daily_notes = {
      folder = "日記",
      date_format = "%Y年%-m月%-d日",
      template = nil,
    },

    templates = {
      folder = "templates",
      date_format = "%Y年%-m月%-d日",
    },

    ui = { enable = false },
  },
  config = function(_, opts)
    require("obsidian").setup(opts)

    local function create_note(folder, template_name)
      return function(o)
        local date = os.date("%Y年%-m月%-d日")
        local filename = (o.args ~= "") and o.args or date
        local fullpath = vim.fn.expand("~/vault/" .. folder .. "/" .. filename .. ".md")
        local is_new = vim.fn.filereadable(fullpath) == 0
        vim.cmd("edit " .. vim.fn.fnameescape(fullpath))
        if is_new then
          vim.schedule(function()
            vim.cmd("ObsidianTemplate " .. template_name)
          end)
        end
      end
    end

    vim.api.nvim_create_user_command("ObsidianMTG", create_note("MTG", "MTG"), { nargs = "?" })
    vim.api.nvim_create_user_command("ObsidianReview", create_note("レビュー", "レビュー"), { nargs = "?" })
  end,
}
