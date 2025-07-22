local wezterm = require 'wezterm'
local M = wezterm.config_builder()
local act = wezterm.action

-- ==================== BASIC CONFIGURATION ====================
M.check_for_updates = true
M.check_for_updates_interval_seconds = 86400

-- ==================== INPUT & ACCESSIBILITY ====================
M.use_ime = true
M.ime_preedit_rendering = 'System'
M.send_composed_key_when_left_alt_is_pressed = true
M.scrollback_lines = 10000

-- ==================== TYPOGRAPHY & READABILITY ====================
M.font = wezterm.font_with_fallback({
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
M.font_size = 10.0
M.line_height = 1.1
M.cell_width = 1.0

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

  clock_time = "#d2b48c",

  battery_full = "#8fbc8f",
  battery_high = "#7dcfff",
  battery_medium = "#e0af68",
  battery_low = "#f7768e",
}

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
M.window_decorations = 'TITLE_BAR | RESIZE'
M.window_background_opacity = 0.95
M.text_background_opacity = 1.0
M.adjust_window_size_when_changing_font_size = false

M.window_padding = {
  left = 8,
  right = 8,
  top = 5,
  bottom = 5,
}

M.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 20,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 20,
}

-- ==================== TAB BAR OPTIMIZATION ====================
M.use_fancy_tab_bar = false
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
  { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo 'Clipboard' },
  { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom 'Clipboard' },

  -- === NAVIGATION (Vim-like) ===
  { key = "h", mods = "CTRL|ALT", action = act.SendKey({ key = "LeftArrow" }) },
  { key = "j", mods = "CTRL|ALT", action = act.SendKey({ key = "DownArrow" }) },
  { key = "k", mods = "CTRL|ALT", action = act.SendKey({ key = "UpArrow" }) },
  { key = "l", mods = "CTRL|ALT", action = act.SendKey({ key = "RightArrow" }) },

  -- === SCROLLING ===
  { key = "j", mods = "CTRL", action = act.ScrollByLine(1) },
  { key = "k", mods = "CTRL", action = act.ScrollByLine(-1) },
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
}

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

-- macOS用バッテリー情報取得
local function get_battery_info()
  local success, stdout, _ = wezterm.run_child_process({
    "pmset", "-g", "batt"
  })

  if success and stdout then
    local battery_level = stdout:match("(%d+)%%")
    if battery_level then
      local level = tonumber(battery_level)
      local battery_icon, color
      if level <= 15 then
        battery_icon, color = "🪫", colors.battery_low
      elseif level <= 30 then
        battery_icon, color = "🔋", colors.battery_medium
      elseif level <= 70 then
        battery_icon, color = "🔋", colors.battery_high
      else
        battery_icon, color = "🔋", colors.battery_full
      end
      return string.format("%s %d%%", battery_icon, level), color
    end
  end
  return "🔋 --", colors.fg_muted
end

-- macOS用ネットワーク情報取得
local function get_network_info()
  local success, stdout, _ = wezterm.run_child_process({
    "networksetup", "-listallhardwareports"
  })

  if success and stdout then
    if stdout:find("Wi%-Fi") then
      return "📶 WiFi", colors.network_wifi
    elseif stdout:find("Ethernet") then
      return "🌐 Ethernet", colors.network_ethernet
    end
  end
  return "📵 Offline", colors.network_error
end

-- Right status bar（macOS版）
wezterm.on("update-right-status", function(window, pane)
  local current_time = os.time()

  if current_time - status_cache.last_network_update >= 15 then
    status_cache.last_network_update = current_time
    local net_text, net_color = get_network_info()
    status_cache.network_name = net_text
    status_cache.network_color = net_color
  end

  if current_time - status_cache.last_battery_update >= 30 then
    status_cache.last_battery_update = current_time
    local bat_text, bat_color = get_battery_info()
    status_cache.battery_info = bat_text
    status_cache.battery_color = bat_color
  end

  local date = wezterm.strftime("%m/%d(%a)")
  local time = wezterm.strftime("%H:%M:%S")

  local status_elements = {
    -- Network
    { Background = { Color = status_cache.network_color } },
    { Foreground = { Color = colors.bg_primary } },
    { Text = " " .. status_cache.network_name .. " " },
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

  window:set_right_status(wezterm.format(status_elements))
end)

-- Left status bar
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
    { Text = " 🍎 " .. workspace .. leader_indicator .. " " },
  }))
end)

-- Helper function for basename
local function get_basename(path)
  if not path then
    return "shell"
  end

  local basename = path:match("([^/]+)$") or path
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

-- Leader key cursor color change
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

return M
