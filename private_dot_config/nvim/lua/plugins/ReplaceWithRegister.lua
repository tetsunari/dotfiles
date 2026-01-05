return {
  "vim-scripts/ReplaceWithRegister",
  cond = true,
  keys = {
    -- { "<leader>", "<Plug>ReplaceWithRegisterOperator" },
    { ",", "<Plug>ReplaceWithRegisterOperator" },
    -- 無効化するために絶対使わないキーバインドを設定
    { "g666001", "<Plug>ReplaceWithRegisterLine" },
    { "g666002", "<Plug>ReplaceWithRegisterVisual" },
  },
}
