vim.keymap.set('n', 'ZZ', '<NOP>')
vim.keymap.set('n', 'ZQ', '<NOP>')

vim.keymap.set('i', 'jj', '<Esc>')

vim.keymap.set({ 'n', 'v' }, 'p', 'p`]')

vim.keymap.set('n', 'x', '"_x')
vim.keymap.set('n', 'X', '"_X')
vim.keymap.set('n', 's', '"_s')

vim.api.nvim_set_var('mapleader', ' ')

