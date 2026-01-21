-- =============================================================================
-- WezTerm Configuration Entry Point
-- モジュール分割版
-- =============================================================================
local wezterm = require("wezterm")

-- モジュールパスを追加（.config/wezterm/ からモジュールを読み込む）
local home = wezterm.home_dir
local module_dir = home .. "/.config/wezterm"
package.path = module_dir .. "/?.lua;" .. module_dir .. "/?/init.lua;" .. package.path

local config = wezterm.config_builder()

-- =============================================================================
-- BASIC CONFIGURATION
-- =============================================================================
-- WSL Ubuntuをデフォルトドメインとして使用
config.default_domain = "WSL:Ubuntu"
config.check_for_updates = true
config.check_for_updates_interval_seconds = 86400

-- タブを閉じた時に前回アクティブだったタブに戻る
config.switch_to_last_active_tab_when_closing_tab = true

-- ステータス更新間隔（モード表示を高速に: 50ms）
config.status_update_interval = 50

-- =============================================================================
-- LOAD MODULES
-- =============================================================================
require("appearance").apply_to_config(config)
require("keymaps").apply_to_config(config)
require("tab").apply_to_config(config)
require("statusbar").apply_to_config(config)
require("workspace").apply_to_config(config)

-- オプショナルモジュール（keymapsの後に読み込む）
require("modules.wsl").apply_to_config(config)
require("modules.notification").apply_to_config(config)

-- =============================================================================
-- INITIALIZATION
-- =============================================================================
local wsl = require("modules.wsl")

-- 最適化：初期化時はPowerShellコマンド実行を避け、デフォルト値を使用
-- 実際のデータは最初の update-right-status イベント以降に取得される
wezterm.on("window-config-reloaded", function(window, pane)
  -- WSL2ネットワークテストはバックグラウンドで実行
  wezterm.time.call_after(500, function()
    wsl.test_wsl_network()
  end)

  wezterm.emit("update-right-status", window, pane)
end)

return config
