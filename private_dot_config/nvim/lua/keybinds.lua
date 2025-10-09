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

vim.keymap.set('x', 'p', 'P', { desc = 'Paste without change register' })
vim.keymap.set('x', 'P', 'p', { desc = 'Paste with change register' })

-- { 'n', 'x' }とすると複数のモードに対応
vim.keymap.set('n', 'X', '"_D', { desc = 'Delete using blackhole register' })
vim.keymap.set('o', 'x', 'd', { desc = 'Delete using x' })

vim.keymap.set('n', '<c-s>', '<cmd>write<cr>', { desc = 'Write' })
vim.keymap.set({ 'n', 'x' }, 'so', ':source<cr>', { silent = true, desc = "Source crrent script" })
