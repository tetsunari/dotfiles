return {}
-- return {
-- 	"nvim-neo-tree/neo-tree.nvim",
-- 	branch = "v3.x",
-- 	dependencies = {
-- 		"nvim-lua/plenary.nvim",
-- 		"nvim-tree/nvim-web-devicons",
-- 		"MunifTanjim/nui.nvim",
-- 		"s1n7ax/nvim-window-picker",
-- 	},
-- 	cmd = "Neotree",
-- 	keys = {
-- 		{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
-- 		{ "<leader>o", "<cmd>Neotree focus<cr>", desc = "Focus Neo-tree" },
-- 	},
-- 	opts = {
-- 		close_if_last_window = true,
-- 		enable_git_status = true,
-- 		enable_diagnostics = true,
-- 		sources = {
-- 			"filesystem",
-- 		},
-- 		default_component_configs = {
-- 			indent = {
-- 				with_markers = true,
-- 				indent_marker = "│",
-- 				last_indent_marker = "└",
-- 				indent_size = 2,
-- 			},
-- 			icon = {
-- 				folder_closed = "",
-- 				folder_open = "",
-- 				folder_empty = "󰜌",
-- 				default = "",
-- 			},
-- 		},
-- 		filesystem = {
-- 			follow_current_file = {
-- 				enabled = true,
-- 				leave_dirs_open = true,
-- 			},
-- 			use_libuv_file_watcher = true, -- パフォーマンス向上
-- 			filtered_items = {
-- 				visible = false,
-- 				hide_dotfiles = false,
-- 				hide_gitignored = false,
-- 				hide_by_name = {
-- 					"node_modules",
-- 					".git",
-- 					".DS_Store",
-- 				},
-- 				never_show = {
-- 					".git",
-- 					".DS_Store",
-- 				},
-- 			},
-- 		},
-- 		window = {
-- 			position = "left",
-- 			width = 30,
-- 			mapping_options = {
-- 				noremap = true,
-- 				nowait = true,
-- 			},
-- 			mappings = {
-- 				["<cr>"] = "open",
-- 				["<esc>"] = "cancel", -- close preview or floating neo-tree window
-- 				["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = true } },
-- 				["l"] = "focus_preview",
-- 				["S"] = "open_split",
-- 				["s"] = "open_vsplit",
-- 				["t"] = "open_tabnew",
-- 				["w"] = "open_with_window_picker",
-- 				["C"] = "close_node",
-- 				["z"] = "close_all_nodes",
-- 				["Z"] = "expand_all_nodes",
-- 				["a"] = {
-- 					"add",
-- 					config = {
-- 						show_path = "none" -- "none", "relative", "absolute"
-- 					}
-- 				},
-- 				["A"] = "add_directory",
-- 				["d"] = "delete",
-- 				["r"] = "rename",
-- 				["y"] = "copy_to_clipboard",
-- 				["x"] = "cut_to_clipboard",
-- 				["p"] = "paste_from_clipboard",
-- 				["c"] = "copy", -- takes text input for destination, also accepts the optional config.show_path option like "add"
-- 				["m"] = "move", -- takes text input for destination, also accepts the optional config.show_path option like "add"
-- 				["q"] = "close_window",
-- 				["R"] = "refresh",
-- 				["?"] = "show_help",
-- 				["<"] = "prev_source",
-- 				[">"] = "next_source",
-- 				["i"] = "show_file_details",
-- 			},
-- 		},
-- 		-- 他のソースの設定
-- 		buffers = {
-- 			follow_current_file = {
-- 				enabled = true,
-- 				leave_dirs_open = false,
-- 			},
-- 		},
-- 		git_status = {
-- 			window = {
-- 				position = "float",
-- 				mappings = {
-- 					["A"]  = "git_add_all",
-- 					["gu"] = "git_unstage_file",
-- 					["ga"] = "git_add_file",
-- 					["gr"] = "git_revert_file",
-- 					["gc"] = "git_commit",
-- 					["gp"] = "git_push",
-- 					["gg"] = "git_commit_and_push",
-- 				}
-- 			}
-- 		},
-- 	},
-- 	config = function(_, opts)
-- 		-- VSCodeとの互換性チェック
-- 		if vim.g.vscode then
-- 			return
-- 		end
--
-- 		require("neo-tree").setup(opts)
--
-- 		-- 自動起動（必要に応じて）
-- 		-- vim.api.nvim_create_autocmd("VimEnter", {
-- 		--   callback = function()
-- 		--     if vim.fn.argc() == 0 then
-- 		--       require("neo-tree.command").execute({ action = "show" })
-- 		--     end
-- 		--   end
-- 		-- })
-- 	end,
-- }
