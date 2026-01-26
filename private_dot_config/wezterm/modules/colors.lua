-- =============================================================================
-- カラーパレット定義（Tokyo Night inspired）
-- 他モジュールから共有して使用
-- =============================================================================
local M = {}

-- Base colors
M.bg_primary = "#1a1b26"
M.bg_secondary = "#24283b"
M.bg_tertiary = "#414868"

-- Text colors
M.fg_primary = "#c0caf5"
M.fg_secondary = "#9aa5ce"
M.fg_muted = "#565f89"

-- Accent colors
M.accent_blue = "#7aa2f7"
M.accent_green = "#9ece6a"
M.accent_yellow = "#e0af68"
M.accent_red = "#f7768e"
M.accent_purple = "#bb9af7"
M.accent_cyan = "#7dcfff"
M.accent_orange = "#d2b48c"
M.accent_teal = "#8fbc8f"

-- Status colors
M.success = "#9ece6a"
M.warning = "#e0af68"
M.error = "#f7768e"
M.info = "#7dcfff"

-- UI要素専用色
M.network_wifi = "#7dcfff"
M.network_ethernet = "#7aa2f7"
M.network_error = "#f7768e"

M.wsl_success = "#9ece6a"
M.wsl_error = "#f7768e"

M.vpn_connected = "#bb9af7"  -- 紫（VPN接続中）

M.clock_time = "#d2b48c"

M.battery_full = "#8fbc8f"
M.battery_high = "#7dcfff"
M.battery_medium = "#e0af68"
M.battery_low = "#f7768e"
M.battery_charging = "#9ece6a"  -- 充電中（緑）

return M
