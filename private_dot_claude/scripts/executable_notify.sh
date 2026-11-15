#!/bin/bash
# =============================================================================
# Claude Code notification script
# macOS: osascriptでネイティブ通知を送信（WezTermがフォーカス中は抑制）
# WSL2 : BELを送信 → WezTerm Luaでフォーカス判定して通知
# =============================================================================

TITLE="${1:-Claude Code}"
MESSAGE="${2:-タスクが完了しました}"

notify_macos() {
    # 現在フォーカスされているアプリを取得
    local front_app
    front_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)

    # WezTermがフォーカス中でなければ通知を送信
    if [ "$front_app" != "wezterm-gui" ]; then
        osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\""
    fi
}

# Claude Codeの親プロセスのPTYを特定して送信
find_claude_tty() {
    local pid=$$
    local tty=""

    # 親プロセスをたどってPTYを探す
    while [[ $pid -gt 1 ]]; do
        tty=$(ps -o tty= -p $pid 2>/dev/null | tr -d ' ')
        if [[ -n "$tty" && "$tty" != "?" ]]; then
            echo "/dev/$tty"
            return 0
        fi
        pid=$(ps -o ppid= -p $pid 2>/dev/null | tr -d ' ')
    done

    return 1
}

notify_wsl() {
    local target_tty
    target_tty=$(find_claude_tty)

    if [[ -n "$target_tty" && -w "$target_tty" ]]; then
        printf '\a' > "$target_tty" 2>/dev/null
    fi
}

if [[ "$(uname -s)" == "Darwin" ]]; then
    notify_macos
else
    notify_wsl
fi
