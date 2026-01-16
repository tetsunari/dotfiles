-- =============================================================================
-- 動的タブタイトル（プロセスアイコン付き + モード表示）
-- =============================================================================
local wezterm = require("wezterm")
local colors = require("modules.colors")

local M = {}

-- =============================================================================
-- アイコン定義（Nerd Fonts）
-- =============================================================================
local ICONS = {
  zsh = wezterm.nerdfonts.dev_terminal,
  bash = wezterm.nerdfonts.dev_terminal,
  fish = wezterm.nerdfonts.dev_terminal,
  sh = wezterm.nerdfonts.dev_terminal,
  nvim = wezterm.nerdfonts.custom_neovim,
  vim = wezterm.nerdfonts.custom_vim,
  docker = wezterm.nerdfonts.dev_docker,
  git = wezterm.nerdfonts.dev_git,
  lg = wezterm.nerdfonts.dev_git,
  lazygit = wezterm.nerdfonts.dev_git,
  ssh = wezterm.nerdfonts.md_server,
  wslhost = wezterm.nerdfonts.md_microsoft_windows,
  -- File Manager
  yazi = wezterm.nerdfonts.md_folder,
  -- AI Tools
  claude = wezterm.nerdfonts.md_robot,
  gemini = wezterm.nerdfonts.md_google_assistant,
  codex = wezterm.nerdfonts.oct_copilot,
  default = wezterm.nerdfonts.dev_terminal,
}

-- 特別表示するプロセス（アイコン + 名前のみ + 背景色）
-- 順序重要: nvimはvimより先にチェック、lazygitはlg/gitより先に
local SPECIAL_PROCESSES_ORDER = {
  "nvim", "lazygit", "lg", "docker", "ssh", "vim", "git",
  "yazi",
  "claude", "gemini", "codex",
}
local SPECIAL_PROCESSES = {
  nvim = { bg = "#57A143" },    -- 緑
  vim = { bg = "#019833" },     -- 緑
  docker = { bg = "#2496ED" },  -- 青
  ssh = { bg = "#FF6B6B" },     -- 赤
  lg = { bg = "#F05032" },      -- オレンジ
  lazygit = { bg = "#F05032", name = "poptab" }, -- poptab として表示
  git = { bg = "#F05032" },     -- オレンジ
  -- File Manager
  yazi = { bg = "#7aa2f7", name = "poptab" },    -- poptab として表示
  -- AI Tools
  claude = { bg = "#D97757" },  -- Anthropic オレンジ
  gemini = { bg = "#4285F4" },  -- Google 青
  codex = { bg = "#10A37F" },   -- OpenAI 緑
}

-- =============================================================================
-- グローバル状態（wezterm.GLOBAL）
-- =============================================================================
-- wezterm.GLOBALを初期化（存在しない場合）
wezterm.GLOBAL = wezterm.GLOBAL or {}
wezterm.GLOBAL.mode_text = wezterm.GLOBAL.mode_text or ""

-- =============================================================================
-- モードごとのカーソル色（OSCエスケープシーケンス用）
-- =============================================================================
local MODE_CURSOR_COLORS = {
  leader = "#9d7cd8",   -- 紫（Leader）
  copy = "#e0af68",     -- 黄色（Copy/Search）
  resize = "#7aa2f7",   -- 青（Resize）
  default = colors.accent_purple,  -- デフォルト（appearance.luaと同じ）
}

-- 前回のカーソル色を記録（不要な更新を避けるため）
local last_cursor_color = nil

-- =============================================================================
-- モード状態の更新
-- =============================================================================
local function setup_mode_tracking()
  wezterm.on("update-status", function(window, pane)
    local mode_text = ""
    local cursor_color = MODE_CURSOR_COLORS.default

    local key_table = window:active_key_table()
    if key_table then
      if key_table == "resize_pane" then
        mode_text = " 󰩨 RESIZE "
        cursor_color = MODE_CURSOR_COLORS.resize
      elseif key_table == "copy_mode" or key_table == "search_mode" then
        mode_text = " 󰆏 COPY "
        cursor_color = MODE_CURSOR_COLORS.copy
      else
        mode_text = " " .. key_table:upper() .. " "
        cursor_color = MODE_CURSOR_COLORS.default
      end
    elseif window:leader_is_active() then
      mode_text = " 󰌌 LEADER "
      cursor_color = MODE_CURSOR_COLORS.leader
    end

    -- モード状態を更新
    wezterm.GLOBAL.mode_text = mode_text

    -- カーソル色変更（OSCエスケープシーケンスを使用）
    if last_cursor_color ~= cursor_color then
      last_cursor_color = cursor_color
      -- OSC 12 でカーソル色を変更: \x1b]12;<color>\x1b\\
      pane:inject_output("\x1b]12;" .. cursor_color .. "\x1b\\")
    end

    -- 左ステータス: ワークスペース名を表示（2つ以上ある場合）
    local workspaces = wezterm.mux.get_workspace_names()
    if #workspaces >= 2 then
      local current_workspace = wezterm.mux.get_active_workspace()
      window:set_left_status(wezterm.format({
        { Background = { Color = colors.bg_tertiary } },
        { Foreground = { Color = colors.fg_primary } },
        { Text = " 󰣀 " .. current_workspace .. " " },
        { Background = { Color = colors.bg_primary } },
        { Text = " " },
      }))
    else
      -- ワークスペースが1つの場合は非表示（タブバー再描画トリガー用）
      window:set_left_status(wezterm.format({
        { Foreground = { Color = colors.bg_primary } },
        { Background = { Color = colors.bg_primary } },
        { Text = mode_text ~= "" and "." or "" },
      }))
    end
  end)
end

-- =============================================================================
-- タブタイトルのフォーマット
-- =============================================================================
local function setup_tab_title()
  wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
    local pane = tab.active_pane

    -- アクティブタブの場合、モード状態を取得
    local mode_text = ""
    local is_zoomed = pane.is_zoomed
    if tab.is_active then
      mode_text = wezterm.GLOBAL.mode_text or ""
    end

    -- WSL環境対応: foreground_process_name を優先、次に tab_title, title をチェック
    local process = pane.foreground_process_name or ""
    local title = pane.title or ""
    local tab_title = tab.tab_title or ""

    -- ベースネーム取得
    local name = process:match("([^/\\]+)$") or process
    name = name:gsub("%.exe$", "")
    local name_lower = name:lower()
    local title_lower = title:lower()
    local tab_title_lower = tab_title:lower()

    -- 特別プロセスの検出
    local is_special = false
    local matched_name = nil
    local matched_proc_info = nil

    -- まず foreground_process_name でチェック（最も信頼性が高い）
    for _, proc in ipairs(SPECIAL_PROCESSES_ORDER) do
      if name_lower:find(proc) then
        is_special = true
        matched_name = proc
        matched_proc_info = SPECIAL_PROCESSES[proc]
        break
      end
    end

    -- process で見つからなかった場合、tab_title と title をチェック
    -- （poptab 用: lazygit, yazi など）
    if not is_special then
      for _, proc in ipairs(SPECIAL_PROCESSES_ORDER) do
        if tab_title_lower:find(proc) or title_lower:find(proc) then
          is_special = true
          matched_name = proc
          matched_proc_info = SPECIAL_PROCESSES[proc]
          break
        end
      end
    end

    -- SSH の特別検出: title が "ssh " で始まる場合（コマンド実行中）
    if not is_special and title_lower:match("^ssh%s") then
      is_special = true
      matched_name = "ssh"
      matched_proc_info = SPECIAL_PROCESSES["ssh"]
    end

    -- 表示用の名前とアイコンを決定（パスではなくプロセス名を使用）
    local display_name = name ~= "" and name or "shell"
    if #display_name > 20 then
      display_name = display_name:sub(1, 17) .. "..."
    end
    local icon = ICONS[name_lower] or ICONS.default
    if is_special then
      icon = ICONS[matched_name] or ICONS.default
      -- カスタム名がある場合はそれを使用（poptab など）
      display_name = matched_proc_info.name or matched_name
    end

    -- zoomアイコン（zoom中のみ表示）
    local zoom_icon = is_zoomed and "󰁌 " or ""

    -- 色とテキストの決定
    local bg, fg, text

    if tab.is_active and mode_text ~= "" then
      -- モード時: モード名のみ、紫背景
      bg = colors.accent_purple
      fg = colors.bg_primary
      text = mode_text
    elseif tab.is_active and is_special and matched_proc_info then
      -- 特別プロセス（アクティブ）: アイコン + プロセス名、専用背景色
      bg = matched_proc_info.bg
      fg = "#ffffff"
      text = " " .. zoom_icon .. icon .. " " .. display_name .. " "
    elseif tab.is_active then
      -- 通常（アクティブ）: 紫背景
      bg = colors.accent_purple
      fg = colors.bg_primary
      text = " " .. zoom_icon .. icon .. " " .. display_name .. " "
    elseif is_special then
      -- 非アクティブ + 特別プロセス: プロセス名のみ
      bg = colors.bg_secondary
      fg = colors.fg_secondary
      text = " " .. zoom_icon .. icon .. " " .. display_name .. " "
    else
      -- 非アクティブ: プロセス名のみ
      bg = colors.bg_secondary
      fg = colors.fg_secondary
      text = " " .. zoom_icon .. icon .. " " .. display_name .. " "
    end

    return {
      { Background = { Color = bg } },
      { Foreground = { Color = fg } },
      { Text = text },
    }
  end)
end

-- =============================================================================
-- 設定適用
-- =============================================================================
function M.apply_to_config(config)
  setup_mode_tracking()
  setup_tab_title()
end

return M
