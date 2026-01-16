-- augroup for this config file
local augroup = vim.api.nvim_create_augroup('init.lua', {})

-- wrapper function to use internal augroup
local function create_autocmd(event, opts)
  vim.api.nvim_create_autocmd(event, vim.tbl_extend('force', {
    group = augroup,
  }, opts))
end

-- https://vim-jp.org/vim-users-jp/2011/02/20/Hack-202.html
-- create_autocmd('BufWritePre', {
--   pattern = '*',
--   callback = function(event)
--     local dir = vim.fs.dirname(event.file)
--     local force = vim.v.cmdbang == 1
--     if vim.fn.isdirectory(dir) == 0
--         and (force or vim.fn.confirm('"' .. dir .. '" does not exist. Create?', "&Yes\n&No") == 1) then
--       vim.fn.mkdir(vim.fn.iconv(dir, vim.opt.encoding:get(), vim.opt.termencoding:get()), 'p')
--     end
--   end,
--   desc = 'Auto mkdir to save file'
-- })

-- 最後に開いていた行を開く
vim.cmd([[
  augroup vimrcEx
    au BufRead * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g`\"" | endif
  augroup END
]])

-- 外部からファイルを変更されたら反映する
vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained" }, {
  pattern = "*",
  command = "checktime",
})

-- quick fix listは横に最大で開く
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.cmd("wincmd J")
  end,
})

-- カスタムハイライトグループを定義
vim.api.nvim_set_hl(0, "YankHighlight", { bg = "#9bd1c3", fg = "#000000" })

-- Yankした範囲をハイライトさせる
vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "YankHighlight", timeout = 200 })
  end,
})

-- 改行コードをLF統一
vim.opt.fileformat = "unix"
vim.opt.fileformats = { "unix", "dos" }

-- 貼り付け時に^Mを自動削除
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("RemoveCR", { clear = true }),
  callback = function()
    -- 貼り付けたテキストから\rを削除
    local text = vim.fn.getreg('"')
    if string.find(text, "\r") then
      vim.fn.setreg('"', string.gsub(text, "\r", ""))
    end
  end,
})
