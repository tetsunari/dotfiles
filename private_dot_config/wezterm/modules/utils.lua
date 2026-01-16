-- =============================================================================
-- ユーティリティ関数
-- UTF-8安全化、PowerShell連携など
-- =============================================================================
local wezterm = require("wezterm")
local M = {}

-- =============================================================================
-- UTF-8 SAFETY FUNCTIONS
-- =============================================================================

-- 動的に取得される文字列（ネットワーク名など）のみを安全化
function M.sanitize_dynamic_string(str)
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

-- =============================================================================
-- PowerShell連携
-- =============================================================================

-- PowerShellコマンドを実行し、UTF-8安全な結果を返す
function M.run_powershell_utf8_safe(command)
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

-- =============================================================================
-- テキスト検証
-- =============================================================================

-- テキストの安全性を検証する関数
function M.validate_text_safety(text)
  if not text or type(text) ~= "string" then
    return false
  end

  -- 空文字列や制御文字のみの場合は無効
  if #text == 0 or text:match("^%s*$") then
    return false
  end

  return true
end

-- =============================================================================
-- ヘルパー関数
-- =============================================================================

-- パスからベースネームを取得
function M.get_basename(path)
  if not path then
    return "shell"
  end

  local basename = path:match("([^\\]+)$") or path:match("([^/]+)$") or path
  basename = basename:gsub("%.exe$", "")

  return basename
end

return M
