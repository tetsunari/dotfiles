-- =============================================================================
-- ステータスバー（右側：CPU・RAM・ネットワーク・バッテリー・時刻）
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
  -- Battery
  battery_full = wezterm.nerdfonts.fa_battery_full,
  battery_three_quarters = wezterm.nerdfonts.fa_battery_three_quarters,
  battery_half = wezterm.nerdfonts.fa_battery_half,
  battery_quarter = wezterm.nerdfonts.fa_battery_quarter,
  battery_empty = wezterm.nerdfonts.fa_battery_empty,
  -- System
  cpu = wezterm.nerdfonts.oct_cpu,
  ram = wezterm.nerdfonts.cod_server,
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
  -- Battery (wezterm.battery_info() を使用)
  battery_text = ICONS.battery_full .. " --",
  battery_color = colors.fg_muted,
  last_battery_update = 0,
  -- CPU
  cpu_text = ICONS.cpu .. " --%",
  cpu_color = colors.accent_blue,
  last_cpu_update = 0,
  -- RAM
  ram_text = ICONS.ram .. " --GB",
  ram_color = colors.accent_purple,
  last_ram_update = 0,
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
  local icon, color

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

  return string.format("%s %.0f%%", icon, charge), color
end

-- =============================================================================
-- ネットワーク情報取得（Windows PowerShell経由）
-- =============================================================================
local function get_network_info()
  local success, stdout, _ = wezterm.run_child_process({
    "powershell.exe",
    "-NoProfile",
    "-Command",
    [[
      $adapter = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
      if ($adapter) {
        if ($adapter.Name -match 'Wi-Fi|WiFi') { 'WiFi' }
        elseif ($adapter.Name -match 'Ethernet') { 'Ethernet' }
        else { 'Connected' }
      } else { 'Offline' }
    ]],
  })

  if success and stdout then
    local result = stdout:gsub("%s+", "")
    if result == "WiFi" then
      return ICONS.wifi .. " WiFi", colors.network_wifi
    elseif result == "Ethernet" then
      return ICONS.ethernet .. " Ethernet", colors.network_ethernet
    elseif result == "Connected" then
      return ICONS.wifi .. " Connected", colors.info
    end
  end

  return ICONS.offline .. " Offline", colors.network_error
end

-- =============================================================================
-- CPU情報取得（tabline.wez cpu.lua より - Windows/WSL対応）
-- =============================================================================
local function get_cpu_info()
  local success, stdout, _

  -- Windows環境（WezTermはWindowsで動作）
  if string.match(wezterm.target_triple, "windows") then
    success, stdout, _ = wezterm.run_child_process({
      "cmd.exe",
      "/C",
      "wmic cpu get loadpercentage",
    })

    if success and stdout then
      local cpu = stdout:match("%d+")
      if cpu then
        return string.format("%s %s%%", ICONS.cpu, cpu), colors.accent_blue
      end
    end
  end

  return ICONS.cpu .. " --%", colors.accent_blue
end

-- =============================================================================
-- RAM情報取得（tabline.wez ram.lua より - Windows対応）
-- =============================================================================
local function get_ram_info()
  local success, stdout, _

  -- Windows環境
  if string.match(wezterm.target_triple, "windows") then
    -- 使用中のメモリを計算（Total - Free）
    success, stdout, _ = wezterm.run_child_process({
      "powershell.exe",
      "-NoProfile",
      "-Command",
      [[
        $os = Get-CimInstance Win32_OperatingSystem
        $used = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB
        [math]::Round($used, 1)
      ]],
    })

    if success and stdout then
      local ram = stdout:match("[%d%.]+")
      if ram then
        return string.format("%s %sGB", ICONS.ram, ram), colors.accent_purple
      end
    end
  end

  return ICONS.ram .. " --GB", colors.accent_purple
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

    -- バッテリー情報の更新（10秒間隔）
    if current_time - status_cache.last_battery_update >= 10 then
      status_cache.last_battery_update = current_time
      status_cache.battery_text, status_cache.battery_color = get_battery_info()
    end

    -- CPU情報の更新（30秒間隔 - 負荷軽減）
    if current_time - status_cache.last_cpu_update >= 30 then
      status_cache.last_cpu_update = current_time
      status_cache.cpu_text, status_cache.cpu_color = get_cpu_info()
    end

    -- RAM情報の更新（30秒間隔 - 負荷軽減）
    if current_time - status_cache.last_ram_update >= 30 then
      status_cache.last_ram_update = current_time
      status_cache.ram_text, status_cache.ram_color = get_ram_info()
    end

    -- 時刻情報（毎回更新）
    local datetime = get_datetime_info()

    -- ステータスバー表示
    local status_elements = {
      -- CPU
      { Background = { Color = status_cache.cpu_color } },
      { Foreground = { Color = colors.bg_primary } },
      { Text = " " .. status_cache.cpu_text .. " " },

      -- RAM
      { Background = { Color = status_cache.ram_color } },
      { Foreground = { Color = colors.bg_primary } },
      { Text = " " .. status_cache.ram_text .. " " },

      -- Windows Network
      { Background = { Color = status_cache.network_color } },
      { Foreground = { Color = colors.bg_primary } },
      { Text = " " .. status_cache.network_text .. " " },

      -- WSL2
      { Background = { Color = wsl.status_cache.status_color } },
      { Foreground = { Color = colors.bg_primary } },
      { Text = " " .. wsl.status_cache.status .. " " },

      -- Date
      { Background = { Color = colors.bg_tertiary } },
      { Foreground = { Color = colors.fg_primary } },
      { Text = " " .. datetime.date .. " " },

      -- Time
      { Background = { Color = colors.clock_time } },
      { Foreground = { Color = colors.bg_primary } },
      { Text = " " .. datetime.time .. " " },

      -- Battery
      { Background = { Color = status_cache.battery_color } },
      { Foreground = { Color = colors.bg_primary } },
      { Text = " " .. status_cache.battery_text .. " " },
    }

    local success, formatted = pcall(wezterm.format, status_elements)
    if success then
      window:set_right_status(formatted)
    else
      window:set_right_status(wezterm.nerdfonts.cod_warning .. " Status Error")
    end
  end)
end

return M
