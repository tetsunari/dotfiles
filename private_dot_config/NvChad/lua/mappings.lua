require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jj", "<ESC>")

map("n", "<leader>,", "^")
map("n", "<leader>.", "$")

-- map("n", "<C-S-]>", "<Tab>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
