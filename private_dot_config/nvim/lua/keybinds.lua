-- zenhan IME自動切り替え設定
if vim.fn.executable('zenhan') == 1 then
  -- InsertモードからNormalモードに切り替わった時にIMEをオフにする
  vim.api.nvim_create_autocmd('ModeChanged', {
    pattern = 'i:*',
    callback = function()
      vim.fn.system('zenhan 0 2>/dev/null')
    end,
  })
  -- Insertモードを抜けた時にIMEをオフにする（念のため）
  vim.api.nvim_create_autocmd('InsertLeave', {
    callback = function()
      vim.fn.system('zenhan 0 2>/dev/null')
    end,
  })
  -- コマンドラインを抜けた時にIMEをオフにする
  vim.api.nvim_create_autocmd('CmdlineLeave', {
    callback = function()
      vim.fn.system('zenhan 0 2>/dev/null')
    end,
  })
end

vim.keymap.set('n', 'ZZ', '<NOP>')
vim.keymap.set('n', 'ZQ', '<NOP>')

vim.keymap.set('i', 'jj', '<Esc>')

vim.keymap.set({ 'n', 'v' }, 'p', 'p`]')

vim.keymap.set('n', 'x', '"_x')
vim.keymap.set('n', 'X', '"_X')
vim.keymap.set('n', 's', '"_s')

vim.api.nvim_set_var('mapleader', ' ')

-- https://zenn.dev/kawarimidoll/books/6064bf6f193b51/viewer/6c77c3
vim.keymap.set('n', 'p', 'p]', { desc = 'Paste and move to the end' })
vim.keymap.set('n', 'P', 'P]', { desc = 'Paste and move to the end' })

-- vim.keymap.set('x', 'p', 'P', { desc = 'Paste without change register' })
-- vim.keymap.set('x', 'P', 'p', { desc = 'Paste with change register' })

-- { 'n', 'x' }とすると複数のモードに対応
-- vim.keymap.set('n', 'X', '"_D', { desc = 'Delete using blackhole register' })
-- vim.keymap.set('o', 'x', 'd', { desc = 'Delete using x' })

vim.keymap.set('n', '<c-s>', '<cmd>write<cr>', { desc = 'Write' })
vim.keymap.set({ 'n', 'x' }, 'so', ':source<cr>', { silent = true, desc = "Source crrent script" })

vim.keymap.set('i', '<c-a>', '<ESC>^i')
vim.keymap.set('i', '<c-d>', '<ESC>s')

-- VSCode
if vim.g.vscode then
  local vscode = require("vscode")

  vim.keymap.set("n", "<c-j>", function()
    vscode.action("workbench.action.terminal.toggleTerminal")
  end)

  vim.keymap.set("n", "gru", function()
    vscode.action("workbench.action.findInFiles")
  end)

  -- goto change
  vim.keymap.set("n", "]c", function()
    vscode.action("workbench.action.editor.nextChange")
  end)
  vim.keymap.set("n", "[c", function()
    vscode.action("workbench.action.editor.previousChange")
  end)

  -- goto error
  vim.keymap.set("n", "]e", function()
    vscode.action("editor.action.marker.nextInFiles")
  end)
  vim.keymap.set("n", "[e", function()
    vscode.action("editor.action.marker.prevInFiles")
  end)

  vim.keymap.set("n", "<space>g", function()
    vscode.action("lazygit-vscode.toggle")
  end)

  vim.keymap.set("n", "<space>y", function()
    vscode.action("yazi-vscode.toggle")
  end)

  vim.keymap.set("n", "<space>u", function()
    vscode.action("git.revertSelectedRanges")
  end)
  vim.keymap.set("n", "<space>+", function()
    vscode.action("git.stageSelectedRanges")
  end)

  vim.keymap.set("n", "<space>j", function()
    vscode.action("workbench.action.navigateDown")
  end)

  vim.keymap.set("n", "<space>k", function()
    vscode.action("workbench.action.navigateUp")
  end)

  vim.keymap.set("n", "<space>h", function()
    vscode.action("workbench.action.navigateLeft")
  end)

  vim.keymap.set("n", "<space>l", function()
    vscode.action("workbench.action.navigateRight")
  end)

  vim.keymap.set("n", "<space>z", function()
    vscode.action("workbench.action.toggleZenMode")
  end)

  vim.keymap.set("n", "<C-w>", function()
    vscode.action("workbench.actin.closeActiveEditor")
  end)
  --
  -- vim.keymap.set("n", "<Space>l", function()
  --   vscode.action("workbench.action.nextEditorInGroup")
  -- end)

  -- vim.keymap.set("n", "<Space>h", function()
  --   vscode.action("workbench.action.previousEditorInGroup")
  -- end)

  vim.keymap.set("n", "<space>w", function()
    vscode.action("workbench.action.closeActiveEditor")
  end)

  vim.keymap.set("n", "<space>q", function()
    vscode.action("workbench.action.closeOtherEditors")
  end)

  -- vim.keymap.set("n", "<space>t", function()
  --   vscode.action("workbench.action.reopenClosedEditor")
  -- end)

  vim.keymap.set("n", "<space>r", function()
    vscode.action("workbench.action.navigateLast")
  end)

  vim.keymap.set("n", "<space>e", function()
    vscode.action("workbench.action.showAllEditors")
  end)

  -- split系はVSCodeで動かないため別途設定が必要
  vim.keymap.set("n", "<space>\\", function()
    vscode.call("workbench.action.splitEditorRight")
    vscode.action("editor.action.revealDefinition")
  end)

  vim.keymap.set("n", "<space>-", function()
    vscode.call("workbench.action.splitEditorDown")
    vscode.action("editor.action.revealDefinition")
  end)

  -- folding
  vim.keymap.set("n", "zc", function()
    vscode.action("editor.fold")
  end)

  vim.keymap.set("n", "zo", function()
    vscode.action("editor.unfold")
  end)

  -- Oil.code
  vim.keymap.set("n", "<space>o", function()
    vscode.action("oil-code.open")
  end)

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "oil",
    callback = function(event)
      local opts = { buffer = event.buf, noremap = true, silent = true }
      vim.keymap.set("n", "<CR>", function()
        vscode.action("oil-code.select")
      end, opts)
      vim.keymap.set("n", "<C-CR>", function()
        vscode.action("oil-code.selectVertical")
      end, opts)
      -- 水平方向に展開するコマンドはないので複数コマンドを同期で連続させる
      vim.keymap.set("n", "<C-s>", function()
        vscode.call("workbench.action.splitEditorDown")
        vscode.call("oil-code.selectTab")
        vscode.call("workbench.action.previousEditorInGroup")
        vscode.call("workbench.action.closeActiveEditor")
      end, opts)

      vim.keymap.set("n", "-", function()
        vscode.action("oil-code.openParent")
      end, opts)
      vim.keymap.set("n", "_", function()
        vscode.action("oil-code.openCwd")
      end, opts)
      vim.keymap.set("n", "<C-l>", function()
        vscode.action("oil-code.refresh")
      end, opts)
    end,
  })
end
