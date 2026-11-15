local is_mac = vim.fn.has('macunix') == 1
local is_linux = vim.fn.has('linux') == 1

-- WSL2向けのzenhan IME自動切り替え設定
if is_linux and not vim.g.vscode and vim.fn.executable('zenhan') == 1 then
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

-- WezTerm連携: OSC 1337 SetUserVarでnvim起動中であることを通知
-- WezTerm側はこれを見て、WSL2ではCtrl+Vを矩形選択として、macOSではCommand+Sを保存キーとしてnvimへ渡す
if not vim.g.vscode and vim.env.TERM_PROGRAM == 'WezTerm' then
  local function wezterm_set_user_var(name, value)
    io.stdout:write(string.format('\027]1337;SetUserVar=%s=%s\007', name, vim.base64.encode(value)))
    io.stdout:flush()
  end
  vim.api.nvim_create_autocmd('VimEnter', {
    callback = function()
      vim.defer_fn(function() wezterm_set_user_var('IN_NVIM', '1') end, 300)
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function() wezterm_set_user_var('IN_NVIM', '0') end,
  })
end

vim.keymap.set('i', 'jj', '<Esc>')

local function paste_after_normalize_cr(keys)
  return function()
    NormalizeCRInRegister(vim.v.register)
    return keys
  end
end

vim.keymap.set('n', 'x', '"_x')
vim.keymap.set('n', 'X', '"_X')
vim.keymap.set('n', 's', '"_s')

vim.api.nvim_set_var('mapleader', ' ')

-- https://zenn.dev/kawarimidoll/books/6064bf6f193b51/viewer/6c77c3
-- Normalモードのp/Pはundo-glow.nvimで設定する
vim.keymap.set('x', 'p', paste_after_normalize_cr('p`]'), { expr = true, desc = 'Paste and move to the end' })
vim.keymap.set('x', 'P', paste_after_normalize_cr('P`]'), { expr = true, desc = 'Paste and move to the end' })

-- vim.keymap.set('x', 'p', 'P', { desc = 'Paste without change register' })
-- vim.keymap.set('x', 'P', 'p', { desc = 'Paste with change register' })

-- { 'n', 'x' }とすると複数のモードに対応
-- vim.keymap.set('n', 'X', '"_D', { desc = 'Delete using blackhole register' })
-- vim.keymap.set('o', 'x', 'd', { desc = 'Delete using x' })

vim.keymap.set('n', '<c-s>', '<cmd>write<cr>', { desc = 'Write' })
if is_mac then
  -- WezTermからCSI-uで届くCommand+S。Oil等のCtrl+S割り当てと分離する
  vim.keymap.set({ 'n', 'i', 'x' }, '<D-s>', '<cmd>write<cr>', { desc = 'Write' })
end
vim.keymap.set({ 'n', 'x' }, 'so', ':source<cr>', { silent = true, desc = "Source crrent script" })

-- Linux/WSL2ではInsertモードの<C-v>をシステムクリップボードの貼り付けに使う
-- macOSでは端末標準のCommand+Vを使い、<C-v>はVim本来の入力操作を維持する
if is_linux then
  vim.keymap.set('i', '<C-v>', '<C-r><C-o>+', { desc = 'Paste from system clipboard' })
end

vim.keymap.set('i', '<c-a>', is_mac and not vim.g.vscode and '<Home>' or '<ESC>^i')
vim.keymap.set('i', '<c-d>', '<ESC>s')

-- Macの単体Neovimでは挿入モードのままEmacs風にカーソルを移動する
if is_mac and not vim.g.vscode then
  local cursor_keys = {
    ['<C-e>'] = '<End>',
    ['<C-b>'] = '<Left>',
    ['<C-f>'] = '<Right>',
  }
  for key, movement in pairs(cursor_keys) do
    vim.keymap.set('i', key, movement)
  end
  -- 補完候補があるときは従来どおり候補の選択に使う
  vim.keymap.set('i', '<C-n>', function()
    return vim.fn.pumvisible() == 1 and '<C-n>' or '<Down>'
  end, { expr = true })
  vim.keymap.set('i', '<C-p>', function()
    return vim.fn.pumvisible() == 1 and '<C-p>' or '<Up>'
  end, { expr = true })
end

-- VSCode
if vim.g.vscode then
  local vscode = require("vscode")

  vim.keymap.set("n", "gd", function()
    vscode.action("editor.action.revealDefinition")
  end)

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

  -- lazygit
  vim.keymap.set("n", "<space>g", function()
    vscode.action("lazygit-vscode.toggle")
  end)

  -- vim.keymap.set("n", "<space>y", function()
  --   vscode.action("yazi-vscode.toggle")
  -- end)

  -- git
  -- <Space>d : 変更のプレビュー (Gitsigns preview_hunk 相当)
  -- カーソル位置のインライン差分（Peek）を表示します
  vim.keymap.set("n", "<space>d", function()
    vscode.action("editor.action.dirtydiff.next")
  end)
  -- <Space>D : 差分ビューを開く (Gitsigns diffthis 相当)
  -- 現在のファイルの全体差分エディタを開きます
  vim.keymap.set("n", "<space>D", function()
    vscode.action("git.openChange")
  end)
  -- <Space>u : 変更の破棄 (Gitsigns reset_hunk 相当)
  -- ビジュアルモードでの選択範囲の破棄にも対応させるため {"n", "v"} にしています
  vim.keymap.set({ "n", "v" }, "<space>u", function()
    vscode.action("git.revertSelectedRanges")
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

  -- macOSではCommand+Wで閉じ、<C-w>はウィンドウ操作のプレフィックスとして維持する
  vim.keymap.set("n", is_mac and "<D-w>" or "<C-w>", function()
    vscode.action("workbench.action.closeActiveEditor")
  end)
  --
  -- vim.keymap.set("n", "<Space>l", function()
  --   vscode.action("workbench.action.nextEditorInGroup")
  -- end)

  -- vim.keymap.set("n", "<Space>h", function()
  --   vscode.action("workbench.action.previousEditorInGroup")
  -- end)

  vim.keymap.set("n", "<space>x", function()
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

  -- LSP系
  vim.keymap.set("n", "K", function()
    vscode.action("editor.action.showHover")
  end)

  vim.keymap.set("n", "gr", function()
    vscode.action("references-view.findReferences")
  end)

  vim.keymap.set("n", "<space>rn", function()
    vscode.action("editor.action.rename")
  end)

  vim.keymap.set("n", "<space>ca", function()
    vscode.action("editor.action.quickFix")
  end)

  vim.keymap.set("n", "gi", function()
    vscode.action("editor.action.goToImplementation")
  end)

  -- ファイル検索
  vim.keymap.set("n", "<space>f", function()
    vscode.action("workbench.action.quickOpen")
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
