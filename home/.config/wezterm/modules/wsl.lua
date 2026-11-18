-- =============================================================================
-- WSL2ネットワーク監視・制御
-- =============================================================================
local wezterm = require("wezterm")
local colors = require("modules.colors")
local act = wezterm.action

local M = {}

-- NerdFont アイコン定義
local ICONS = {
  wsl_checking = wezterm.nerdfonts.md_magnify,
  wsl_connected = wezterm.nerdfonts.md_earth,
  wsl_error = wezterm.nerdfonts.md_close_circle,
  refresh = wezterm.nerdfonts.md_refresh,
}

-- WSL2ステータスキャッシュ
M.status_cache = {
  status = ICONS.wsl_checking .. " WSL",
  status_color = colors.fg_muted,
  last_update = 0,
  detailed_info = "Checking...",
}

-- WSL2ネットワーク状態テスト（絵文字付き・UTF-8安全版・非同期版）
function M.test_wsl_network()
  -- HTTP接続テスト（非同期バージョン）
  -- タイムアウトを3秒→1秒に短縮して起動を高速化
  local success, stdout, _ = wezterm.run_child_process({
    "wsl", "timeout", "1", "/home/linuxbrew/.linuxbrew/bin/curl", "-s", "--connect-timeout", "1", "-I", "https://www.google.com"
  })

  if success and stdout and (stdout:find("200 OK") or stdout:find("HTTP/")) then
    M.status_cache.status = ICONS.wsl_connected .. " WSL"
    M.status_cache.status_color = colors.wsl_success
    M.status_cache.detailed_info = "WSL2 Network: Connected"
  else
    M.status_cache.status = ICONS.wsl_error .. " WSL"
    M.status_cache.status_color = colors.wsl_error
    M.status_cache.detailed_info = "WSL2 Network: No access"
  end

  M.status_cache.last_update = os.time()
end

-- WSL2制御キーバインドを設定に追加
function M.apply_to_config(config)
  -- WSL2情報表示
  table.insert(config.keys, {
    key = "i",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local info = string.format(
        "WSL2 Network Status\n\nStatus: %s\nDetails: %s\nLast Updated: %s",
        M.status_cache.status,
        M.status_cache.detailed_info,
        os.date("%H:%M:%S", M.status_cache.last_update)
      )
      window:toast_notification(ICONS.wsl_connected .. " WSL2 Info", info, nil, 2000)
    end)
  })

  -- WSL2ステータス更新
  table.insert(config.keys, {
    key = "u",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      M.status_cache.last_update = 0
      M.test_wsl_network()
      window:toast_notification(ICONS.refresh .. " WSL2", "Status updated: " .. M.status_cache.status, nil, 2000)
    end)
  })

  -- WSL2再起動
  table.insert(config.keys, {
    key = "R",
    mods = "LEADER|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      wezterm.run_child_process({"wsl", "--shutdown"})
      window:toast_notification(ICONS.refresh .. " WSL2", "Restarting...", nil, 2000)

      wezterm.time.call_after(3, function()
        M.status_cache.last_update = 0
      end)
    end)
  })
end

return M
