#!/bin/bash
# =============================================================================
# Claude Code notification script for wezterm + WSL2
# セキュリティ・低負荷・高効率を重視したハイブリッド実装
#
# 参考: https://dev.classmethod.jp/articles/shuntaka-claude-code-terminal-life/
#       https://github.com/skanehira/dotfiles/tree/master/claude/hooks
# =============================================================================
set -euo pipefail

TITLE="${1:-Claude Code}"
MESSAGE="${2:-通知}"

# =============================================================================
# セキュリティ: 入力サニタイズ
# =============================================================================
# 改行・タブ・制御文字を除去
TITLE="${TITLE//[$'\n\r\t']/}"
MESSAGE="${MESSAGE//[$'\n\r\t']/}"

# 長さ制限（DoS防止）
TITLE="${TITLE:0:100}"
MESSAGE="${MESSAGE:0:500}"

# =============================================================================
# 方法1: OSC 777 を現在のPTYに送信（最軽量・約1ms以下）
# =============================================================================
send_osc777() {
    local tty

    # 親プロセスのTTYを探す
    tty=$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' ') || true

    if [[ -n "$tty" && "$tty" != "?" ]]; then
        local pts="/dev/$tty"
        if [[ -w "$pts" ]]; then
            printf '\033]777;notify;%s;%s\033\\' "$TITLE" "$MESSAGE" > "$pts" 2>/dev/null
            return 0
        fi
    fi

    # フォールバック: 書き込み可能な最初のPTYに送信
    for pts in /dev/pts/*; do
        if [[ -w "$pts" && "$pts" != "/dev/pts/ptmx" ]]; then
            printf '\033]777;notify;%s;%s\033\\' "$TITLE" "$MESSAGE" > "$pts" 2>/dev/null
            return 0
        fi
    done

    return 1
}

# =============================================================================
# 方法2: Windows Toast 通知（PowerShell バックグラウンド実行）
# =============================================================================
send_windows_toast() {
    local ps_path="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
    [[ -x "$ps_path" ]] || return 1

    # セキュリティ: シングルクォートエスケープ
    local safe_title="${TITLE//\'/\'\'}"
    local safe_message="${MESSAGE//\'/\'\'}"

    # バックグラウンドで実行（非ブロッキング）
    "$ps_path" -NoProfile -NonInteractive -Command "
        Add-Type -AssemblyName System.Windows.Forms
        \$balloon = New-Object System.Windows.Forms.NotifyIcon
        \$balloon.Icon = [System.Drawing.SystemIcons]::Information
        \$balloon.BalloonTipTitle = '$safe_title'
        \$balloon.BalloonTipText = '$safe_message'
        \$balloon.Visible = \$true
        \$balloon.ShowBalloonTip(3000)
        Start-Sleep -Milliseconds 100
        \$balloon.Dispose()
    " >/dev/null 2>&1 &
}

# =============================================================================
# メイン処理
# =============================================================================
# OSC 777を試行、失敗したらWindowsトーストにフォールバック
if ! send_osc777; then
    send_windows_toast
fi

# Bell（追加のアテンション用）
printf '\a' 2>/dev/null || true
