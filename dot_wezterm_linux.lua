local wezterm = require 'wezterm'
local M = wezterm.config_builder()
local act = wezterm.action

-- ==================== BASIC CONFIGURATION ====================
M.default_domain = 'WSL:Ubuntu'
M.check_for_updates = true
M.check_for_updates_interval_seconds = 86400
-- M.disable_default_key_bindings = true 

-- 通知設定（OSC 777/9 エスケープシーケンス対応）
M.notification_handling = "SuppressFromFocusedWindow"

-- ==================== INPUT & ACCESSIBILITY ====================
M.use_ime = true
M.ime_preedit_rendering = 'System'
M.send_composed_key_when_left_alt_is_pressed = true
M.scrollback_lines = 10000

-- ==================== TYPOGRAPHY & READABILITY ====================
M.font = wezterm.font_with_fallback({
  {
    family = "UDEV Gothic 35NF",
    stretch = 'UltraExpanded',
    weight = "ExtraBlack",
  },
  {
    family = "Firge35Nerd Console",
    stretch = 'Expanded',
    weight = "Black",
  },
  {
    family = "JetBrains Mono",
    weight = "Medium",
  },
  {
    family = "Symbols Nerd Font",
  },
})
M.font_size = 8.5
M.line_height = 1.0
-- M.cell_width = 1.0

-- ==================== VISUAL DESIGN SYSTEM ====================
-- Unified color palette (Tokyo Night inspired but optimized for readability)
local colors = {
  -- Base colors
  bg_primary = "#1a1b26",
  bg_secondary = "#24283b",
  bg_tertiary = "#414868",

  -- Text colors
  fg_primary = "#c0caf5",
  fg_secondary = "#9aa5ce",
  fg_muted = "#565f89",

  -- Accent colors
  accent_blue = "#7aa2f7",
  accent_green = "#9ece6a",
  accent_yellow = "#e0af68",
  accent_red = "#f7768e",
  accent_purple = "#bb9af7",
  accent_cyan = "#7dcfff",
  accent_orange = "#d2b48c",
  accent_teal = "#8fbc8f",

  -- Status colors
  success = "#9ece6a",
  warning = "#e0af68",
  error = "#f7768e",
  info = "#7dcfff",

  -- UI要素専用色
  network_wifi = "#7dcfff",
  network_ethernet = "#7aa2f7",
  network_error = "#f7768e",

  wsl_success = "#9ece6a",
  wsl_error = "#f7768e",

  clock_time = "#d2b48c",

  battery_full = "#8fbc8f",
  battery_high = "#7dcfff",
  battery_medium = "#e0af68",
  battery_low = "#f7768e",
}

-- M.color_scheme = "Kanagawa (Gogh)"
M.color_scheme = "Tokyo Night Storm (Gogh)"
M.colors = {
  cursor_bg = colors.accent_purple,
  cursor_border = colors.accent_purple,
  cursor_fg = colors.bg_primary,

  selection_bg = colors.bg_tertiary,
  selection_fg = colors.fg_primary,

  split = colors.accent_blue,

  tab_bar = {
    background = colors.bg_primary,
    active_tab = {
      bg_color = colors.accent_purple,
      fg_color = colors.bg_primary,
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = colors.bg_secondary,
      fg_color = colors.fg_secondary,
    },
    inactive_tab_hover = {
      bg_color = colors.bg_tertiary,
      fg_color = colors.fg_primary,
    },
    new_tab = {
      bg_color = colors.bg_secondary,
      fg_color = colors.fg_muted,
    },
    new_tab_hover = {
      bg_color = colors.bg_tertiary,
      fg_color = colors.fg_primary,
    },
  },

  copy_mode_active_highlight_bg = { Color = colors.accent_green },
  copy_mode_active_highlight_fg = { Color = colors.bg_primary },
  copy_mode_inactive_highlight_bg = { Color = colors.bg_tertiary },
  copy_mode_inactive_highlight_fg = { Color = colors.fg_primary },

  visual_bell = colors.accent_blue,
}

-- ==================== WINDOW & LAYOUT ====================
M.window_decorations = 'RESIZE'
M.window_background_opacity = 0.75
M.text_background_opacity = 0.85
M.adjust_window_size_when_changing_font_size = false

M.window_padding = {
  left = 5,
  right = 2,
  top = 3,
  bottom = 0,
}

M.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 20,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 20,
}

-- ==================== TAB BAR OPTIMIZATION ====================
M.use_fancy_tab_bar = false
-- M.tab_bar_at_bottom = true
M.tab_max_width = 25
M.hide_tab_bar_if_only_one_tab = false

-- ==================== PANE MANAGEMENT ====================
M.inactive_pane_hsb = {
  hue = 1.0,
  saturation = 0.8,
  brightness = 0.4,
}

-- ==================== CURSOR & ANIMATION ====================
M.default_cursor_style = "SteadyBar"
M.animation_fps = 60
M.cursor_thickness = '2pt'

-- ==================== SCROLLING & PERFORMANCE ====================
M.enable_scroll_bar = true
M.min_scroll_bar_height = '3cell'

-- ==================== LEADER KEY SYSTEM ====================
M.leader = { key = "g", mods = "CTRL", timeout_milliseconds = 2000, }

-- ==================== OPTIMIZED KEY BINDINGS ====================
M.keys = {
  -- === BASIC OPERATIONS ===
  -- Left Control + C/V: コピー&ペースト（Macスタイル）
  { key = "c", mods = "CTRL", action = act.CopyTo 'Clipboard' },
  { key = "v", mods = "CTRL", action = act.PasteFrom 'Clipboard' },

  -- Right Control + C: プロセスの終了（Ctrl+Cシグナル送信）
  { key = "c", mods = "CTRL|SHIFT", action = act.SendKey { key = "c", mods = "CTRL" } },

  -- === NAVIGATION (Vim-like) ===
  { key = "h", mods = "CTRL|ALT", action = act.SendKey({ key = "LeftArrow" }) },
  { key = "j", mods = "CTRL|ALT", action = act.SendKey({ key = "DownArrow" }) },
  { key = "k", mods = "CTRL|ALT", action = act.SendKey({ key = "UpArrow" }) },
  { key = "l", mods = "CTRL|ALT", action = act.SendKey({ key = "RightArrow" }) },

  -- === SCROLLING ===
  { key = "j", mods = "CTRL", action = act.ScrollByLine(1) },
  { key = "k", mods = "CTRL", action = act.ScrollByLine(-1) },
  -- { key = "k", mods = "CTRL", action = act.SendString("\x05\x0b") },
  { key = "j", mods = "CTRL|SHIFT", action = act.ScrollByPage(0.5) },
  { key = "k", mods = "CTRL|SHIFT", action = act.ScrollByPage(-0.5) },
  { key = "G", mods = "CTRL|SHIFT", action = act.ScrollToBottom },

  -- === PANE MANAGEMENT ===
  { key = "\\", mods = "LEADER", action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "-", mods = "LEADER", action = act.SplitVertical { domain = "CurrentPaneDomain" } },
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "w", mods = "LEADER", action = act.ActivatePaneDirection("Next") },
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane { confirm = true } },
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

  -- === PANE RESIZING ===
  { key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
  { key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
  { key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 3 }) },
  { key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 3 }) },
  -- { key = "r",lmodes = "LEADER", action = act.ActivateKeyTable { name = "resize_pane", one_shot = false }, },

  -- === TAB MANAGEMENT ===
  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
  { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
  { key = "1", mods = "LEADER", action = act.ActivateTab(0) },
  { key = "2", mods = "LEADER", action = act.ActivateTab(1) },
  { key = "3", mods = "LEADER", action = act.ActivateTab(2) },
  { key = "4", mods = "LEADER", action = act.ActivateTab(3) },
  { key = "5", mods = "LEADER", action = act.ActivateTab(4) },

  -- === UTILITY ===
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  { key = "r", mods = "LEADER", action = act.ReloadConfiguration },
  { key = "f", mods = "LEADER", action = act.Search("CurrentSelectionOrEmptyString") },

  -- === FONT SIZE ===
  { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL", action = act.ResetFontSize },

  -- === Shift + Enterで改行 ===
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString('\n') }
}

-- M.key_tables = {
--   resize_pane = {
--     { key = "h", action = act.AdjustPaneSize{ "Left", 1 } },
--     { key = "l", action = act.AdjustPaneSize{ "Right", 1 } },
--     { key = "k", action = act.AdjustPaneSize{ "Up", 1 } },
--     { key = "j", action = act.AdjustPaneSize{ "Down", 1 } },
--     { key = "Enter", action = "PopKeyTable" },
--   },
-- }

-- ==================== UTF-8 SAFETY FUNCTIONS ====================
-- 動的に取得される文字列（ネットワーク名など）のみを安全化
local function sanitize_dynamic_string(str)
  if not str then return "Unknown" end

  -- UTF-8バイトシーケンスをチェックして、問題がある場合は安全な文字列に置換
  local safe_str = str

  -- 制御文字と非ASCII文字の問題をチェック
  local has_problem = false
  for i = 1, #str do
    local byte = string.byte(str, i)
    -- 制御文字（0-31, 127）や高位バイト（128-255）で問題が起きやすいパターン
    if byte < 32 or byte == 127 or (byte > 127 and byte < 192) then
      has_problem = true
      break
    end
  end

  if has_problem then
    -- 問題がある場合は安全な代替文字列を使用
    if str:find("Wi%-Fi") or str:find("WiFi") or str:find("無線") then
      safe_str = "WiFi"
    elseif str:find("Ethernet") or str:find("イーサネット") then
      safe_str = "Ethernet"
    else
      safe_str = "Network"
    end
  else
    -- 問題がない場合は長さのみチェック
    if #safe_str > 15 then
      safe_str = safe_str:sub(1, 12) .. "..."
    end
  end

  return safe_str
end

-- PowerShellコマンドを実行し、UTF-8安全な結果を返す
local function run_powershell_utf8_safe(command)
  -- UTF-8 BOM付きで出力を強制
  local wrapped_command = string.format([[
    $OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
    %s
  ]], command)

  local success, stdout, stderr = wezterm.run_child_process({
    "powershell.exe",
    "-NoProfile",
    "-Command",
    wrapped_command
  })

  if success and stdout then
    -- 改行と余分な空白を除去
    local cleaned = stdout:gsub("[\r\n]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return cleaned
  end

  return nil
end

-- ==================== STATUS BAR SYSTEM ====================
M.status_update_interval = 1000

-- Cache system for status bar information
local status_cache = {
  network_name = "🌐 Network",
  network_color = colors.accent_cyan,
  battery_info = "🔋 --",
  battery_color = colors.fg_muted,
  last_network_update = 0,
  last_battery_update = 0,
}

-- WSL2ステータスキャッシュ
local wsl_status_cache = {
  status = "🔍 WSL",
  status_color = colors.fg_muted,
  last_update = 0,
  detailed_info = "Checking...",
}

-- バッテリー情報取得（絵文字付き・UTF-8安全版）
local function get_battery_info()
  local command = [[
    try {
      $battery = Get-CimInstance -Class Win32_Battery -ErrorAction Stop
      $level = $battery.EstimatedChargeRemaining
      if ($level -ne $null) {
        [int]$level
      } else {
        'N/A'
      }
    } catch {
      'N/A'
    }
  ]]

  local result = run_powershell_utf8_safe(command)

  if result and result ~= "N/A" then
    local battery_level = tonumber(result)
    if battery_level then
      local battery_icon, color
      if battery_level <= 15 then
        battery_icon, color = "🪫", colors.battery_low
      elseif battery_level <= 30 then
        battery_icon, color = "🔋", colors.battery_medium
      elseif battery_level <= 70 then
        battery_icon, color = "🔋", colors.battery_high
      else
        battery_icon, color = "🔋", colors.battery_full
      end
      return string.format("%s %d%%", battery_icon, battery_level), color
    end
  end
  return "🔋 --", colors.fg_muted
end

-- ネットワーク情報取得（絵文字付き・UTF-8安全版）
local function get_network_info()
  local command = [[
    try {
      $adapter = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
      if ($adapter) {
        $name = $adapter.Name
        # 安全な識別子のみ返す
        if ($name -match 'Wi-Fi|WiFi') {
          'WiFi'
        } elseif ($name -match 'Ethernet') {
          'Ethernet'
        } else {
          'Connected'
        }
      } else {
        'Offline'
      }
    } catch {
      'Error'
    }
  ]]

  local result = run_powershell_utf8_safe(command)

  if result then
    local display_name, color
    if result == "WiFi" then
      display_name, color = "📶 WiFi", colors.network_wifi
    elseif result == "Ethernet" then
      display_name, color = "🌐 Ethernet", colors.network_ethernet
    elseif result == "Connected" then
      display_name, color = "🔗 Connected", colors.info
    else
      display_name, color = "📵 Offline", colors.network_error
    end
    return display_name, color
  end

  return "📵 Offline", colors.network_error
end

-- WSL2ネットワーク状態テスト（絵文字付き・UTF-8安全版・非同期版）
local function test_wsl_network()
  -- HTTP接続テスト（非同期バージョン）
  -- タイムアウトを3秒→1秒に短縮して起動を高速化
  local success, stdout, _ = wezterm.run_child_process({
    "wsl", "timeout", "1", "/home/linuxbrew/.linuxbrew/bin/curl", "-s", "--connect-timeout", "1", "-I", "https://www.google.com"
  })

  if success and stdout and (stdout:find("200 OK") or stdout:find("HTTP/")) then
    wsl_status_cache.status = "🌐 WSL"
    wsl_status_cache.status_color = colors.wsl_success
    wsl_status_cache.detailed_info = "WSL2 Network: Connected"
  else
    wsl_status_cache.status = "❌ WSL"
    wsl_status_cache.status_color = colors.wsl_error
    wsl_status_cache.detailed_info = "WSL2 Network: No access"
  end

  wsl_status_cache.last_update = os.time()
end

-- テキストの安全性を検証する関数
local function validate_text_safety(text)
  if not text or type(text) ~= "string" then
    return false
  end

  -- 空文字列や制御文字のみの場合は無効
  if #text == 0 or text:match("^%s*$") then
    return false
  end

  return true
end

-- Right status bar（絵文字対応・エラーハンドリング強化版）
wezterm.on("update-right-status", function(window, pane)
  local current_time = os.time()

  -- 各種情報の更新
  if current_time - wsl_status_cache.last_update >= 60 then
    test_wsl_network()
  end

  if current_time - status_cache.last_network_update >= 15 then
    status_cache.last_network_update = current_time
    local net_text, net_color = get_network_info()
    if validate_text_safety(net_text) then
      status_cache.network_name = net_text
      status_cache.network_color = net_color
    end
  end

  if current_time - status_cache.last_battery_update >= 30 then
    status_cache.last_battery_update = current_time
    local bat_text, bat_color = get_battery_info()
    if validate_text_safety(bat_text) then
      status_cache.battery_info = bat_text
      status_cache.battery_color = bat_color
    end
  end

  -- 時刻情報（絵文字付き）
  local date = wezterm.strftime("%m/%d(%a)")
  local time = wezterm.strftime("%H:%M:%S")

  -- 各要素の安全性を確認
  if not validate_text_safety(status_cache.network_name) then
    status_cache.network_name = "🌐 Network"
  end
  if not validate_text_safety(wsl_status_cache.status) then
    wsl_status_cache.status = "🔍 WSL"
  end
  if not validate_text_safety(status_cache.battery_info) then
    status_cache.battery_info = "🔋 --"
  end

  -- ステータスバー表示（絵文字付き・エラー回避版）
  local status_elements = {
    -- Windows Network
    { Background = { Color = status_cache.network_color } },
    { Foreground = { Color = colors.bg_primary } },
    { Text = " " .. status_cache.network_name .. " " },
    { Background = { Color = colors.bg_primary } },

    -- WSL2
    { Background = { Color = wsl_status_cache.status_color } },
    { Foreground = { Color = colors.bg_primary } },
    { Text = " " .. wsl_status_cache.status .. " " },
    { Background = { Color = colors.bg_primary } },

    -- Date
    { Background = { Color = colors.bg_tertiary } },
    { Foreground = { Color = colors.fg_primary } },
    { Text = " 📅 " .. date .. " " },
    { Background = { Color = colors.bg_primary } },

    -- Time
    { Background = { Color = colors.clock_time } },
    { Foreground = { Color = colors.bg_primary } },
    { Text = " 🕐 " .. time .. " " },
    { Background = { Color = colors.bg_primary } },

    -- Battery
    { Background = { Color = status_cache.battery_color } },
    { Foreground = { Color = colors.bg_primary } },
    { Text = " " .. status_cache.battery_info .. " " },
  }

  -- エラーハンドリング付きでフォーマット実行
  local success, formatted = pcall(wezterm.format, status_elements)
  if success then
    window:set_right_status(formatted)
  else
    -- フォールバック表示（絵文字付き）
    window:set_right_status("⚠️ Status Error")
    -- デバッグのためにエラーをログ出力
    wezterm.log_error("Status format error - falling back to safe display")
  end
end)

-- Left status bar（絵文字付き）
wezterm.on("update-left-status", function(window, pane)
  local workspace = window:active_workspace()
  local leader_indicator = ""
  local bg_color = colors.accent_purple

  if window:leader_is_active() then
    leader_indicator = " ⚡ LEADER"
    bg_color = colors.accent_yellow
  end

  window:set_left_status(wezterm.format({
    { Background = { Color = bg_color } },
    { Foreground = { Color = colors.bg_primary } },
    { Text = " 🚀 " .. workspace .. leader_indicator .. " " },
  }))
end)

-- Helper function for basename
local function get_basename(path)
  if not path then
    return "shell"
  end

  local basename = path:match("([^\\]+)$") or path:match("([^/]+)$") or path
  basename = basename:gsub("%.exe$", "")

  return basename
end

-- Customize tab title
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local title = tab.tab_title
  if title and #title > 0 then
    title = title
  else
    local process_name = tab.active_pane.foreground_process_name or "shell"
    title = get_basename(process_name)
  end

  local tab_number = tab.tab_index + 1

  return {
    { Text = string.format(" %d:%s ", tab_number, title) },
  }
end)

-- ==================== LEADER KEY CURSOR COLOR CHANGE ====================
wezterm.on("leader-key-status-changed", function(window, pane)
  local overrides = window:get_config_overrides() or {}

  if window:leader_is_active() then
    overrides.colors = {
      cursor_bg = colors.accent_yellow,
      cursor_border = colors.accent_yellow
    }
  else
    overrides.colors = nil
  end

  window:set_config_overrides(overrides)
end)

-- ==================== WSL2 CONTROL KEYBINDINGS ====================
table.insert(M.keys, {
  key = "i",
  mods = "LEADER",
  action = wezterm.action_callback(function(window, pane)
    local info = string.format(
      "WSL2 Network Status\n\nStatus: %s\nDetails: %s\nLast Updated: %s",
      wsl_status_cache.status,
      wsl_status_cache.detailed_info,
      os.date("%H:%M:%S", wsl_status_cache.last_update)
    )
    window:toast_notification("🌐 WSL2 Info", info, nil, 2000)
  end)
})

table.insert(M.keys, {
  key = "u",
  mods = "LEADER",
  action = wezterm.action_callback(function(window, pane)
    wsl_status_cache.last_update = 0
    test_wsl_network()
    window:toast_notification("🔄 WSL2", "Status updated: " .. wsl_status_cache.status, nil, 2000)
  end)
})

table.insert(M.keys, {
  key = "R",
  mods = "LEADER|SHIFT",
  action = wezterm.action_callback(function(window, pane)
    wezterm.run_child_process({"wsl", "--shutdown"})
    window:toast_notification("🔄 WSL2", "Restarting...", nil, 2000)

    wezterm.time.call_after(3, function()
      wsl_status_cache.last_update = 0
    end)
  end)
})

-- ==================== INITIALIZATION ====================
-- 最適化：初期化時はPowerShellコマンド実行を避け、デフォルト値を使用
-- 実際のデータは最初の update-right-status イベント以降に取得される
wezterm.on("window-config-reloaded", function(window, pane)
  -- 初期化時は即座にデフォルト値を設定（起動時間を短縮）
  status_cache.last_battery_update = os.time()
  status_cache.last_network_update = os.time()

  -- WSL2ネットワークテストはバックグラウンドで実行
  -- （但し、実際には status_update_interval で制御される）
  wezterm.time.call_after(500, function()
    test_wsl_network()
  end)

  wezterm.emit('update-right-status', window, pane)
end)

return M
