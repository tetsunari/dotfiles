-- =============================================================================
-- WezTerm Notification Module
-- バックグラウンド時のみ通知を表示する（bellイベント使用）
-- =============================================================================
local wezterm = require("wezterm")
local M = {}

-- 最後の通知時刻（デバウンス用）
local last_notification_time = 0
local DEBOUNCE_SEC = 1

function M.apply_to_config(config)
  config.audible_bell = "Disabled"
  config.visual_bell = {
    fade_in_duration_ms = 0,
    fade_out_duration_ms = 0,
  }
end

wezterm.on("bell", function(window, pane)
  -- ウィンドウがフォーカスされていない、かつアクティブペインからのbellの場合のみ通知
  local dominated = window:active_pane():pane_id() == pane:pane_id()
  if dominated and not window:is_focused() then
    local now = os.time()
    if now - last_notification_time >= DEBOUNCE_SEC then
      last_notification_time = now
      window:toast_notification("Claude Code", "タスクが完了しました", nil, 4000)
    end
  end
end)

return M
