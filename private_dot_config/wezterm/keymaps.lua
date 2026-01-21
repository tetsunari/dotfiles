-- =============================================================================
-- キーバインド設定
-- =============================================================================
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- ペインサイズを均等化（近似）
local function equalize_panes()
  return wezterm.action_callback(function(window, pane)
    local tab = pane:tab()
    local tab_size = tab:get_size()
    local panes = tab:panes_with_info()

    if #panes < 2 then return end

    -- 横分割（左右）の均等化
    local target_cols = math.floor(tab_size.cols / 2)
    for _, info in ipairs(panes) do
      if info.left == 0 then
        local current_cols = info.width
        local diff = current_cols - target_cols
        if diff > 0 then
          window:perform_action(act.AdjustPaneSize({ "Left", diff }), info.pane)
        elseif diff < 0 then
          window:perform_action(act.AdjustPaneSize({ "Right", -diff }), info.pane)
        end
        break
      end
    end

    -- 縦分割（上下）の均等化
    local target_rows = math.floor(tab_size.rows / 2)
    for _, info in ipairs(panes) do
      if info.top == 0 then
        local current_rows = info.height
        local diff = current_rows - target_rows
        if diff > 0 then
          window:perform_action(act.AdjustPaneSize({ "Up", diff }), info.pane)
        elseif diff < 0 then
          window:perform_action(act.AdjustPaneSize({ "Down", -diff }), info.pane)
        end
        break
      end
    end
  end)
end

function M.apply_to_config(config)
  -- =============================================================================
  -- LEADER KEY SYSTEM
  -- =============================================================================
  config.leader = { key = "g", mods = "CTRL", timeout_milliseconds = 2000 }

  -- =============================================================================
  -- KEY BINDINGS
  -- =============================================================================
  config.keys = {
    -- === BASIC OPERATIONS ===
    -- Left Control + C/V: コピー&ペースト（Macスタイル）
    { key = "c", mods = "CTRL", action = act.CopyTo("Clipboard") },
    { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },

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
    { key = "Tab", mods = "LEADER", action = act.ActivatePaneDirection("Next") },
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
    { key = "R", mods = "LEADER|SHIFT", action = act.ReloadConfiguration },
    { key = "f", mods = "LEADER", action = act.Search("CurrentSelectionOrEmptyString") },

    -- === QUICK SELECT ===
    { key = "s", mods = "LEADER", action = act.QuickSelect },

    -- === FONT SIZE ===
    { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
    { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
    { key = "0", mods = "CTRL", action = act.ResetFontSize },

    -- === Shift + Enterで改行 ===
    { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },

    -- === RESIZE MODE ===
    { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

    -- === POPUP ALTERNATIVES (tmux popup 代替) ===
    -- lazygit を新タブで起動（現在のディレクトリで）
    {
      key = "g",
      mods = "LEADER",
      action = wezterm.action_callback(function(window, pane)
        local cwd = pane:get_current_working_dir()
        local cwd_path = cwd and cwd.file_path or nil
        window:perform_action(
          act.SpawnCommandInNewTab {
            label = "lazygit",
            domain = "CurrentPaneDomain",
            cwd = cwd_path,
            args = { "/home/linuxbrew/.linuxbrew/bin/lazygit" },
          },
          pane
        )
      end),
    },
    -- yazi を新タブで起動（現在のディレクトリで）
    {
      key = "y",
      mods = "LEADER",
      action = wezterm.action_callback(function(window, pane)
        local cwd = pane:get_current_working_dir()
        local cwd_path = cwd and cwd.file_path or nil
        window:perform_action(
          act.SpawnCommandInNewTab {
            label = "yazi",
            domain = "CurrentPaneDomain",
            cwd = cwd_path,
            args = { "/home/linuxbrew/.linuxbrew/bin/yazi" },
          },
          pane
        )
      end),
    },
  }

  -- =============================================================================
  -- KEY TABLES (モード)
  -- =============================================================================
  config.key_tables = {
    -- ペインリサイズモード: Leader + r で入り、hjkl で連続調整、Escape/q で終了
    resize_pane = {
      { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
      { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
      { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
      { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
      { key = "0", action = equalize_panes() },
      { key = "Escape", action = "PopKeyTable" },
      { key = "q", action = "PopKeyTable" },
    },
  }

end

return M
