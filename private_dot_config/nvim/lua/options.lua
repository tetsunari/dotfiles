-- vim.cmd('colorscheme catppuccin-macchiato')
vim.cmd('colorscheme tokyonight-storm')
-- vim.cmd('colorscheme kanagawa-wave')

-- グローバルオプション(autocmdの外で一度だけ設定)
vim.opt.termguicolors = true
vim.opt.scrolloff = 5
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = 'split'
vim.opt.clipboard = 'unnamedplus'
vim.opt.virtualedit = 'onemore'
vim.opt.swapfile = false

-- ウィンドウローカルオプション
vim.opt.number = true
-- vim.opt.relativenumber = true
vim.opt.cursorline = true
-- vim.opt.signcolumn = 'yes:1' -- 画面がちらついたらコメントアウト外す
vim.opt.wrap = false

-- バッファローカルオプション
vim.opt.tabstop = 2
vim.opt.shiftwidth = 0
vim.opt.expandtab = true

vim.opt.helplang = { "ja", "en" }

vim.opt.clipboard:append('unnamedplus,unnamed')

-- 行末から次の行へ移動できる
vim.opt.whichwrap = 'b,s,h,l,<,>,[,],~'
-- 空白文字の可視化
vim.opt.list = true

vim.opt.listchars = {
  -- tab = "| ", -- Tab
  -- trail = "-", -- 行末スペース
  -- eol = "↲", -- 改行
  extends = "»", -- ウィンドウ幅狭い時の後方省略
  precedes = "«", -- ウィンドウ幅狭い時の前方省略
  nbsp = "%", -- 不可視のスペース
}

