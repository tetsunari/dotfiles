return {
  "stevearc/oil.nvim",
  keys = {
    { "<leader>o", "<cmd>Oil<CR>", desc = "Open Oil file explorer", silent = true },
  },
  cmd = "Oil",
  opts = {
    default_file_explorer = true,
    columns = {
      "icon",
    },
    buf_options = {
      buflisted = false,
      bufhidden = "hide",
    },
    win_options = {
      wrap = false,
      signcolumn = "no",
      cursorcolumn = false,
      foldcolumn = "0",
      spell = false,
      list = false,
      conceallevel = 3,
      concealcursor = "nvic",
    },
    delete_to_trash = false,
    skip_confirm_for_simple_edits = false,
    prompt_save_on_select_new_entry = true,
    cleanup_delay_ms = 2000,
    lsp_file_methods = {
      enabled = true,
      timeout_ms = 1000,
      autosave_changes = false,
    },
    constrain_cursor = "editable",
    watch_for_changes = false,
    keymaps = {
      ["g?"] = "actions.show_help",
      ["<CR>"] = "actions.select",
      ["<C-s>"] = { "actions.select", opts = { vertical = true }, desc = "Open the entry in a vertical split" },
      ["<C-h>"] = { "actions.select", opts = { horizontal = true }, desc = "Open the entry in a horizontal split" },
      ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
      ["<C-p>"] = "actions.preview",
      ["<C-c>"] = "actions.close",
      ["<C-l>"] = "actions.refresh",
      ["-"] = "actions.parent",
      ["_"] = "actions.open_cwd",
      ["`"] = "actions.cd",
      ["~"] = { "actions.cd", opts = { scope = "tab" }, desc = ":tcd to the current oil directory", mode = "n" },
      ["gs"] = "actions.change_sort",
      ["gx"] = "actions.open_external",
      ["g."] = "actions.toggle_hidden",
      ["g\\"] = "actions.toggle_trash",
      ["gy"] = "actions.yank_entry",
      -- カスタムキーマップ: grug-farとの連携（元の設定から移植）
      ["gR"] = {
        callback = function()
          local oil = require("oil")
          local prefills = { paths = oil.get_current_dir() }

          local ok, grug_far = pcall(require, "grug-far")
          if not ok then
            vim.notify("grug-far is not installed", vim.log.levels.WARN)
            return
          end

          if not grug_far.has_instance("explorer") then
            grug_far.open({
              instanceName = "explorer",
              prefills = prefills,
            })
          else
            grug_far.open_instance("explorer")
            grug_far.update_instance_prefills("explorer", prefills, false)
          end
        end,
        desc = "Search in directory with grug-far",
      },
    },
    use_default_keymaps = true,
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name, bufnr)
        return false
      end,
      natural_order = "fast",
      case_insensitive = false,
      sort = {
        { "type", "asc" },
        { "name", "asc" },
      },
      highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
        return nil
      end,
    },
    extra_scp_args = {},
    git = {
      add = function(path)
        return true
      end,
      mv = function(src_path, dest_path)
        return true
      end,
      rm = function(path)
        return true
      end,
    },
    float = {
      padding = 2,
      max_width = 0,
      max_height = 0,
      border = "rounded",
      win_options = {
        winblend = 0,
      },
      get_win_title = nil,
      -- VSCodeライクに右側にプレビューを表示
      preview_split = "right",
      override = function(conf)
        return conf
      end,
    },
    preview = {
      update_on_cursor_moved = true,
      preview_method = "fast_scratch",
      disable_preview = function(filename)
        return false
      end,
      win_options = {},
    },
    confirmation = {
      max_width = 0.9,
      min_width = { 40, 0.4 },
      width = nil,
      max_height = 0.9,
      min_height = { 5, 0.1 },
      height = nil,
      border = "rounded",
      win_options = {
        winblend = 0,
      },
    },
    progress = {
      max_width = 0.9,
      min_width = { 40, 0.4 },
      width = nil,
      max_height = { 10, 0.9 },
      min_height = { 5, 0.1 },
      height = nil,
      border = "rounded",
      minimized_border = "none",
      win_options = {
        winblend = 0,
      },
    },
    ssh = {
      border = "rounded",
    },
    keymaps_help = {
      border = "rounded",
    },
  },
}
