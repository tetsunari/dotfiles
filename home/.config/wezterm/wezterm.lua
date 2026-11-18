-- =============================================================================
-- WezTerm Configuration Entry Point
-- モジュール分割版（macOS / Windows(WSL2) 共通）
-- macOS: mise の [dotfiles] で ~/.config/wezterm/ に symlink を置く
-- Windows: mise bootstrap の post-dotfiles hook で %USERPROFILE%\.wezterm.lua と .config\wezterm\ にコピー
-- =============================================================================
local wezterm = require("wezterm")

-- モジュールパスを追加（.config/wezterm/ からモジュールを読み込む）
local home = wezterm.home_dir
local module_dir = home .. "/.config/wezterm"
package.path = module_dir .. "/?.lua;" .. module_dir .. "/?/init.lua;" .. package.path

local utils = require("modules.utils")
local config = wezterm.config_builder()

-- =============================================================================
-- BASIC CONFIGURATION
-- =============================================================================
if utils.is_windows then
  -- WSL Ubuntuをデフォルトドメインとして使用
  config.default_domain = "WSL:Ubuntu"
  -- GPU/OpenGL ドライバーの不具合を避けるため CPU で描画する（公式: front_end の Software）
  config.front_end = "Software"
end
config.check_for_updates = true
config.check_for_updates_interval_seconds = 86400

if utils.is_mac then
  -- 通知設定（OSC 777/9 エスケープシーケンス対応）
  config.notification_handling = "SuppressFromFocusedWindow"
end

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

if utils.is_windows then
  -- オプショナルモジュール（keymapsの後に読み込む）
  local wsl = require("modules.wsl")
  wsl.apply_to_config(config)
  require("modules.notification").apply_to_config(config)

  -- 最適化：初期化時はPowerShellコマンド実行を避け、デフォルト値を使用
  -- 実際のデータは最初の update-right-status イベント以降に取得される
  wezterm.on("window-config-reloaded", function(window, pane)
    -- WSL2ネットワークテストはバックグラウンドで実行
    wezterm.time.call_after(500, function()
      wsl.test_wsl_network()
    end)

    wezterm.emit("update-right-status", window, pane)
  end)
end

return config
