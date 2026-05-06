return {
  {
    "kevinhwang91/nvim-hlslens",
    cond = true,
    event = { "VeryLazy" },
    config = function()
      require("hlslens").setup({
        build_position_cb = function(plist, _, _, _)
          require("scrollbar.handlers.search").handler.show(plist.start_pos)
        end,
        override_lens = function(render, posList, nearest, idx)
          local text, chunks
          ---@diagnostic disable-next-line: deprecated
          local lnum, col = unpack(posList[idx])
          local cnt = #posList
          text = ("[%d/%d]"):format(idx, cnt)
          if nearest then
            chunks = { { " ", "Ignore" }, { text, "HlSearchLensNear" } }
          else
            chunks = { { " ", "Ignore" }, { text, "HlSearchLens" } }
          end
          render.setVirt(0, lnum - 1, col - 1, chunks, nearest)
        end,
      })
      local kopts = { noremap = true, silent = true }

      -- VSCode では silent! を付けて E486 / パターンエコーを抑制する
      local silent_prefix = vim.g.vscode and "silent! " or ""

      vim.api.nvim_set_keymap(
        "n",
        "n",
        ([[<Cmd>%sexecute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]]):format(silent_prefix),
        kopts
      )
      vim.api.nvim_set_keymap(
        "n",
        "N",
        ([[<Cmd>%sexecute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]]):format(silent_prefix),
        kopts
      )

      if vim.g.vscode then
        -- lasterisk.search() のパターンエコーを silent! で抑制
        vim.keymap.set("n", "*", function()
          vim.cmd("silent! lua require('lasterisk').search()")
          require("hlslens").start()
        end, kopts)
        vim.keymap.set({ "n", "x" }, "g*", function()
          vim.cmd("silent! lua require('lasterisk').search({is_whole=false})")
          require("hlslens").start()
        end, kopts)
        vim.api.nvim_set_keymap("n", "#", [[<Cmd>silent! normal! #<CR><Cmd>lua require('hlslens').start()<CR>]], kopts)
        vim.api.nvim_set_keymap("n", "g#", [[<Cmd>silent! normal! g#<CR><Cmd>lua require('hlslens').start()<CR>]], kopts)
      else
        vim.keymap.set("n", "*", function()
          require("lasterisk").search()
          require("hlslens").start()
        end)
        vim.keymap.set({ "n", "x" }, "g*", function()
          require("lasterisk").search({ is_whole = false })
          require("hlslens").start()
        end)
        vim.api.nvim_set_keymap("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
        vim.api.nvim_set_keymap("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
        vim.api.nvim_set_keymap("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)
      end

      vim.api.nvim_set_keymap("n", "<Esc><Esc>", "<Cmd>noh<CR>", kopts)

      vim.cmd([[
        highlight HlSearchLensNear guifg=white guibg=olive
        highlight HlSearchLens guifg=#777777 guibg=#FFFFFFFF
      ]])
    end,
  },
  {
    "rapan931/lasterisk.nvim",
    lazy = true,
  },
}
