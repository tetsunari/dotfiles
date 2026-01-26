-- =============================================================================
-- ステータスバー（右側：ネットワーク・バッテリー・時刻）
-- tabline.wez のコンポーネントを参考に実装
-- =============================================================================
local wezterm = require("wezterm")
local colors = require("modules.colors")
local wsl = require("modules.wsl")

local M = {}

-- =============================================================================
-- NERD FONTS アイコン定義
-- =============================================================================
local ICONS = {
  -- Network
  wifi = wezterm.nerdfonts.md_wifi,
  ethernet = wezterm.nerdfonts.md_ethernet,
  offline = wezterm.nerdfonts.md_wifi_off,
  -- VPN
  vpn = wezterm.nerdfonts.md_shield_lock,
  -- Battery (通常)
  battery_full = wezterm.nerdfonts.fa_battery_full,
  battery_three_quarters = wezterm.nerdfonts.fa_battery_three_quarters,
  battery_half = wezterm.nerdfonts.fa_battery_half,
  battery_quarter = wezterm.nerdfonts.fa_battery_quarter,
  battery_empty = wezterm.nerdfonts.fa_battery_empty,
  -- Battery (充電中)
  battery_charging_100 = wezterm.nerdfonts.md_battery_charging_100,
  battery_charging_80 = wezterm.nerdfonts.md_battery_charging_80,
  battery_charging_60 = wezterm.nerdfonts.md_battery_charging_60,
  battery_charging_40 = wezterm.nerdfonts.md_battery_charging_40,
  battery_charging_20 = wezterm.nerdfonts.md_battery_charging_20,
  -- Calendar
  calendar = wezterm.nerdfonts.fa_calendar,
}

-- 時刻に応じたアイコン（tabline.wez datetime.lua より）
local HOUR_TO_ICON = {
  ["00"] = wezterm.nerdfonts.md_clock_time_twelve_outline,
  ["01"] = wezterm.nerdfonts.md_clock_time_one_outline,
  ["02"] = wezterm.nerdfonts.md_clock_time_two_outline,
  ["03"] = wezterm.nerdfonts.md_clock_time_three_outline,
  ["04"] = wezterm.nerdfonts.md_clock_time_four_outline,
  ["05"] = wezterm.nerdfonts.md_clock_time_five_outline,
  ["06"] = wezterm.nerdfonts.md_clock_time_six_outline,
  ["07"] = wezterm.nerdfonts.md_clock_time_seven_outline,
  ["08"] = wezterm.nerdfonts.md_clock_time_eight_outline,
  ["09"] = wezterm.nerdfonts.md_clock_time_nine_outline,
  ["10"] = wezterm.nerdfonts.md_clock_time_ten_outline,
  ["11"] = wezterm.nerdfonts.md_clock_time_eleven_outline,
  ["12"] = wezterm.nerdfonts.md_clock_time_twelve,
  ["13"] = wezterm.nerdfonts.md_clock_time_one,
  ["14"] = wezterm.nerdfonts.md_clock_time_two,
  ["15"] = wezterm.nerdfonts.md_clock_time_three,
  ["16"] = wezterm.nerdfonts.md_clock_time_four,
  ["17"] = wezterm.nerdfonts.md_clock_time_five,
  ["18"] = wezterm.nerdfonts.md_clock_time_six,
  ["19"] = wezterm.nerdfonts.md_clock_time_seven,
  ["20"] = wezterm.nerdfonts.md_clock_time_eight,
  ["21"] = wezterm.nerdfonts.md_clock_time_nine,
  ["22"] = wezterm.nerdfonts.md_clock_time_ten,
  ["23"] = wezterm.nerdfonts.md_clock_time_eleven,
}

-- =============================================================================
-- STATUS BAR CACHE
-- =============================================================================
local status_cache = {
  -- Network
  network_text = ICONS.wifi .. " Network",
  network_color = colors.accent_cyan,
  last_network_update = 0,
  -- VPN
  vpn_name = nil,  -- nil = 未接続
  last_vpn_update = 0,
  -- Battery (wezterm.battery_info() を使用)
  battery_text = ICONS.battery_full .. " --",
  battery_color = colors.fg_muted,
  last_battery_update = 0,
}

-- =============================================================================
-- バッテリー情報取得（wezterm.battery_info() API を使用）
-- =============================================================================
local function get_battery_info()
  local batteries = wezterm.battery_info()
  if #batteries == 0 then
    return ICONS.battery_full .. " AC", colors.fg_muted
  end

  local b = batteries[1]
  local charge = b.state_of_charge * 100
  local state = b.state  -- "Charging", "Discharging", "Full", "Empty", "Unknown"
  local icon, color

  -- 充電中の場合
  if state == "Charging" then
    color = colors.battery_charging
    if charge <= 20 then
      icon = ICONS.battery_charging_20
    elseif charge <= 40 then
      icon = ICONS.battery_charging_40
    elseif charge <= 60 then
      icon = ICONS.battery_charging_60
    elseif charge <= 80 then
      icon = ICONS.battery_charging_80
    else
      icon = ICONS.battery_charging_100
    end
  -- 通常（放電中/満充電）の場合
  else
    if charge <= 10 then
      icon = ICONS.battery_empty
      color = colors.battery_low
    elseif charge <= 25 then
      icon = ICONS.battery_quarter
      color = colors.battery_medium
    elseif charge <= 50 then
      icon = ICONS.battery_half
      color = colors.battery_high
    elseif charge <= 75 then
      icon = ICONS.battery_three_quarters
      color = colors.battery_high
    else
      icon = ICONS.battery_full
      color = colors.battery_full
    end
  end

  return string.format("%s %.0f%%", icon, charge), color
end

-- =============================================================================
-- ネットワーク情報取得（Windows PowerShell経由 - デフォルトルートで検出）
-- =============================================================================
local function get_network_info()
  local success, stdout, _ = wezterm.run_child_process({
    "powershell.exe",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Command",
    [[
      $routes = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue
      if ($routes) {
        $best = $routes | ForEach-Object {
          $adapter = Get-NetAdapter -InterfaceIndex $_.InterfaceIndex -ErrorAction SilentlyContinue
          if ($adapter -and $adapter.Status -eq 'Up') {
            [PSCustomObject]@{
              Route = $_
              Adapter = $adapter
              TotalMetric = $_.RouteMetric + $_.InterfaceMetric
            }
          }
        } | Where-Object { $_ -ne $null } | Sort-Object TotalMetric | Select-Object -First 1

        if ($best) {
          $a = $best.Adapter
          if ($a.PhysicalMediaType -match 'Wireless|Native 802.11' -or $a.InterfaceDescription -match 'Wireless|Wi-Fi|802.11') { 'WiFi' }
          elseif ($a.PhysicalMediaType -eq '802.3' -or $a.Name -match 'Ethernet') { 'Ethernet' }
          else { 'Connected' }
        } else { 'Offline' }
      } else { 'Offline' }
    ]],
  })

  if success and stdout then
    local result = stdout:gsub("%s+", "")
    if result == "Ethernet" then
      return ICONS.ethernet .. " Ethernet", colors.network_ethernet
    elseif result == "WiFi" then
      return ICONS.wifi .. " WiFi", colors.network_wifi
    elseif result == "Connected" then
      return ICONS.wifi .. " Connected", colors.info
    end
  end

  return ICONS.offline .. " Offline", colors.network_error
end

-- =============================================================================
-- VPN接続状態取得（Windows組み込みVPN - Get-VpnConnection使用）
-- =============================================================================
local function get_vpn_info()
  local success, stdout, _ = wezterm.run_child_process({
    "powershell.exe",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Command",
    [[
      $vpn = Get-VpnConnection -ErrorAction SilentlyContinue | Where-Object { $_.ConnectionStatus -eq 'Connected' } | Select-Object -First 1
      if ($vpn) { $vpn.Name } else { '' }
    ]],
  })

  if success and stdout then
    local name = stdout:gsub("%s+", "")
    if name ~= "" then
      return name
    end
  end

  return nil
end

-- =============================================================================
-- 時刻情報取得（動的アイコン付き）
-- =============================================================================
local function get_datetime_info()
  local time = wezterm.time.now()
  local hour = time:format("%H")
  local date = time:format("%m/%d(%a)")
  local time_str = time:format("%H:%M:%S")

  local clock_icon = HOUR_TO_ICON[hour] or wezterm.nerdfonts.md_clock_outline

  return {
    date = ICONS.calendar .. " " .. date,
    time = clock_icon .. " " .. time_str,
  }
end

-- =============================================================================
-- APPLY TO CONFIG
-- =============================================================================
function M.apply_to_config(config)
  wezterm.on("update-right-status", function(window, pane)
    local current_time = os.time()

    -- WSL状態の更新（60秒間隔）
    if current_time - wsl.status_cache.last_update >= 60 then
      wsl.test_wsl_network()
    end

    -- ネットワーク情報の更新（15秒間隔）
    if current_time - status_cache.last_network_update >= 15 then
      status_cache.last_network_update = current_time
      status_cache.network_text, status_cache.network_color = get_network_info()
    end

    -- VPN情報の更新（15秒間隔）
    if current_time - status_cache.last_vpn_update >= 15 then
      status_cache.last_vpn_update = current_time
      status_cache.vpn_name = get_vpn_info()
    end

    -- バッテリー情報の更新（10秒間隔）
    if current_time - status_cache.last_battery_update >= 10 then
      status_cache.last_battery_update = current_time
      status_cache.battery_text, status_cache.battery_color = get_battery_info()
    end

    -- 時刻情報（毎回更新）
    local datetime = get_datetime_info()

    -- ステータスバー表示
    local status_elements = {
      -- Windows Network
      { Background = { Color = status_cache.network_color } },
      { Foreground = { Color = colors.bg_primary } },
      { Text = " " .. status_cache.network_text .. " " },

      -- WSL2
      { Background = { Color = wsl.status_cache.status_color } },
      { Foreground = { Color = colors.bg_primary } },
      { Text = " " .. wsl.status_cache.status .. " " },
    }

    -- VPN（接続時のみ表示）
    if status_cache.vpn_name then
      table.insert(status_elements, { Background = { Color = colors.vpn_connected } })
      table.insert(status_elements, { Foreground = { Color = colors.bg_primary } })
      table.insert(status_elements, { Text = " " .. ICONS.vpn .. " " .. status_cache.vpn_name .. " " })
    end

    -- Date
    table.insert(status_elements, { Background = { Color = colors.bg_tertiary } })
    table.insert(status_elements, { Foreground = { Color = colors.fg_primary } })
    table.insert(status_elements, { Text = " " .. datetime.date .. " " })

    -- Time
    table.insert(status_elements, { Background = { Color = colors.clock_time } })
    table.insert(status_elements, { Foreground = { Color = colors.bg_primary } })
    table.insert(status_elements, { Text = " " .. datetime.time .. " " })

    -- Battery
    table.insert(status_elements, { Background = { Color = status_cache.battery_color } })
    table.insert(status_elements, { Foreground = { Color = colors.bg_primary } })
    table.insert(status_elements, { Text = " " .. status_cache.battery_text .. " " })

    local success, formatted = pcall(wezterm.format, status_elements)
    if success then
      window:set_right_status(formatted)
    else
      window:set_right_status(wezterm.nerdfonts.cod_warning .. " Status Error")
    end
  end)
end

return M
