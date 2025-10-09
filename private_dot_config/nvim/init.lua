require 'function'
require 'keybinds'
require 'plugin'
require 'options'

vim.opt.clipboard:append('unnamedplus,unnamed')

vim.opt.whichwrap = 'b,s,h,l,<,>,[,],~'

vim.api.nvim_create_user_command(
  'InitLua',
  function()
    vim.cmd.edit(vim.fn.stdpath('config') .. '/init.lua')
  end,
  { desc = 'Open init.lua' }
)

