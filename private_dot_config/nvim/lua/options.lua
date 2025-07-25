vim.cmd('colorscheme tokyonight-storm')

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
  pattern = '*',

  group = vim.api.nvim_create_augroup('buffer_set_options', {}),

  callback = function()
    vim.api.nvim_set_option('termguicolors', true)
    vim.api.nvim_set_option('scrolloff', 5)
    vim.api.nvim_set_option('ignorecase', true)
    vim.api.nvim_set_option('smartcase', true)
    vim.api.nvim_set_option('smartcase', true)
    vim.api.nvim_set_option('inccommand', 'split')
    vim.api.nvim_set_option('clipboard', 'unnamedplus')
    vim.api.nvim_set_option('virtualedit', 'onemore')
    vim.api.nvim_win_set_option(0, 'number', true)
    vim.api.nvim_win_set_option(0, 'cursorline', true)
    -- vim.api.nvim_win_set_option(0, 'signcolumn', 'yes:1') -- 画面がちらついたらコメントアウト外す:w
    vim.api.nvim_win_set_option(0, 'wrap', false)
    vim.api.nvim_buf_set_option(0, 'tabstop', 2)
    vim.api.nvim_buf_set_option(0, 'shiftwidth', 0)
    vim.api.nvim_buf_set_option(0, 'expandtab', true)
  end,
})

