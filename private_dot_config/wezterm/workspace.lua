-- =============================================================================
-- ワークスペース管理
-- =============================================================================
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- スクラッチワークスペースから戻る前のワークスペースを記録
local previous_workspace = nil

-- =============================================================================
-- ヘルパー関数
-- =============================================================================

-- スクラッチワークスペースをトグル
local function toggle_scratch_workspace()
  return wezterm.action_callback(function(window, pane)
    local current = wezterm.mux.get_active_workspace()

    if current == "scratch" then
      -- スクラッチから戻る
      local target = previous_workspace or "default"
      window:perform_action(act.SwitchToWorkspace({ name = target }), pane)
    else
      -- スクラッチへ移動
      previous_workspace = current
      window:perform_action(act.SwitchToWorkspace({ name = "scratch" }), pane)
    end
  end)
end

-- 次のワークスペースへ（スクラッチをスキップ）
local function switch_to_next_workspace()
  return wezterm.action_callback(function(window, pane)
    local workspaces = wezterm.mux.get_workspace_names()
    local current = wezterm.mux.get_active_workspace()

    -- スクラッチを除外
    local filtered = {}
    for _, ws in ipairs(workspaces) do
      if ws ~= "scratch" then
        table.insert(filtered, ws)
      end
    end

    -- 現在のインデックスを取得
    local current_index = 1
    for i, ws in ipairs(filtered) do
      if ws == current then
        current_index = i
        break
      end
    end

    -- 次のワークスペースへ
    local next_index = current_index + 1
    if next_index > #filtered then
      next_index = 1
    end

    if #filtered > 0 then
      window:perform_action(act.SwitchToWorkspace({ name = filtered[next_index] }), pane)
    end
  end)
end

-- 前のワークスペースへ（スクラッチをスキップ）
local function switch_to_prev_workspace()
  return wezterm.action_callback(function(window, pane)
    local workspaces = wezterm.mux.get_workspace_names()
    local current = wezterm.mux.get_active_workspace()

    -- スクラッチを除外
    local filtered = {}
    for _, ws in ipairs(workspaces) do
      if ws ~= "scratch" then
        table.insert(filtered, ws)
      end
    end

    -- 現在のインデックスを取得
    local current_index = 1
    for i, ws in ipairs(filtered) do
      if ws == current then
        current_index = i
        break
      end
    end

    -- 前のワークスペースへ
    local prev_index = current_index - 1
    if prev_index < 1 then
      prev_index = #filtered
    end

    if #filtered > 0 then
      window:perform_action(act.SwitchToWorkspace({ name = filtered[prev_index] }), pane)
    end
  end)
end

-- ワークスペース選択メニュー
local function show_workspace_selector()
  return wezterm.action_callback(function(window, pane)
    -- ワークスペースのリストを作成（スクラッチを除外）
    local workspaces = {}
    local index = 1
    for _, name in ipairs(wezterm.mux.get_workspace_names()) do
      if name ~= "scratch" then
        table.insert(workspaces, {
          id = name,
          label = string.format("%d. %s", index, name),
        })
        index = index + 1
      end
    end

    -- 選択メニューを起動（キーテーブルは使用しない）
    window:perform_action(
      act.InputSelector({
        action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
          if id then
            inner_window:perform_action(act.SwitchToWorkspace({ name = id }), inner_pane)
          end
        end),
        title = "Select workspace",
        choices = workspaces,
        fuzzy = true,
      }),
      pane
    )
  end)
end

-- =============================================================================
-- 設定適用
-- =============================================================================
function M.apply_to_config(config)
  -- キーバインドを追加
  config.keys = config.keys or {}

  -- Leader + w: ワークスペース選択
  table.insert(config.keys, {
    key = "w",
    mods = "LEADER",
    action = show_workspace_selector(),
  })

  -- Leader + W: 新規ワークスペース作成
  table.insert(config.keys, {
    key = "W",
    mods = "LEADER|SHIFT",
    action = act.PromptInputLine({
      description = "Create new workspace:",
      action = wezterm.action_callback(function(window, pane, line)
        if line and line ~= "" then
          window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
        end
      end),
    }),
  })

  -- Leader + `: スクラッチワークスペーストグル
  table.insert(config.keys, {
    key = "`",
    mods = "LEADER",
    action = toggle_scratch_workspace(),
  })

  -- Leader + Shift + n/p: 次/前のワークスペース
  table.insert(config.keys, {
    key = "N",
    mods = "LEADER|SHIFT",
    action = switch_to_next_workspace(),
  })
  table.insert(config.keys, {
    key = "P",
    mods = "LEADER|SHIFT",
    action = switch_to_prev_workspace(),
  })

  -- Leader + Shift + D: 現在のワークスペースを削除（CLI経由で全ペインをkill）
  table.insert(config.keys, {
    key = "D",
    mods = "LEADER|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      local current = wezterm.mux.get_active_workspace()

      -- defaultワークスペースは削除不可
      if current == "default" then
        return
      end

      -- 先にdefaultワークスペースに切り替え
      window:perform_action(act.SwitchToWorkspace({ name = "default" }), pane)

      -- CLIで対象ワークスペースの全ペインを取得してkill
      wezterm.time.call_after(0.3, function()
        local success, stdout, stderr = wezterm.run_child_process({
          "wezterm", "cli", "list", "--format", "json"
        })

        if success then
          local panes_list = wezterm.json_parse(stdout)
          for _, p in ipairs(panes_list) do
            if p.workspace == current then
              wezterm.run_child_process({
                "wezterm", "cli", "kill-pane", "--pane-id", tostring(p.pane_id)
              })
            end
          end
        end
      end)
    end),
  })

end

return M
