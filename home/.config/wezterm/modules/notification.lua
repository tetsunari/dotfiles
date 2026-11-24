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
  -- notify.sh が herdr の外から送る文言入りの通知（OSC 777）も、ベルと同じくフォーカス中は出さない
  config.notification_handling = "SuppressFromFocusedWindow"
end

-- ベルは herdr の中の Claude Code から、入力が要る時だけ鳴る（notify.sh）。
-- herdr は通知の文言を渡せないので、notify.sh が書いたファイルから文言と場所（workspace / tab / pane）を読む。
-- 1行目は書いた時刻で、FRESH_SEC より古いもの（別のベルの分）は使わず決まった文言を出す
local HERDR_NOTIFY_FILE = [[\\wsl.localhost\Ubuntu\tmp\claude-herdr-notify.txt]]
local FRESH_SEC = 10
local DEFAULT_MESSAGE = "❗ ユーザーの指示が必要です"

local function read_herdr_notify()
  local file = io.open(HERDR_NOTIFY_FILE, "r")
  if not file then
    return nil
  end
  local written = tonumber(file:read("l"))
  local message = file:read("l")
  local location = file:read("l")
  local herdr_focused = file:read("l")
  file:close()
  if not written or os.time() - written > FRESH_SEC then
    return nil
  end
  return message, location, herdr_focused
end

wezterm.on("bell", function(window, pane)
  local message, location, herdr_focused = read_herdr_notify()
  local dominated = window:active_pane():pane_id() == pane:pane_id()
  local should_notify
  if herdr_focused == "true" or herdr_focused == "false" then
    -- herdr の中の Claude から: WezTerm で herdr を表示し、herdr でもそのペインを見ている時だけ抑える。
    -- herdr の別の workspace・tab・ペインや、WezTerm の別タブを見ている時は気づけないので通知する
    should_notify = not (window:is_focused() and dominated and herdr_focused == "true")
  else
    -- それ以外は、ウィンドウがフォーカスされていない、かつアクティブペインからのbellの場合のみ通知
    should_notify = dominated and not window:is_focused()
  end
  if should_notify then
    local now = os.time()
    if now - last_notification_time >= DEBOUNCE_SEC then
      last_notification_time = now
      local body = message or DEFAULT_MESSAGE
      if location then
        body = body .. "\n" .. location
      end
      window:toast_notification("Claude Code", body, nil, 4000)
    end
  end
end)

return M
