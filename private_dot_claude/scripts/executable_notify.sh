#!/bin/bash
# =============================================================================
# Claude Code notification script for WezTerm + WSL2
# BELを送信 → WezTerm Luaでフォーカス判定して通知
# =============================================================================

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

target_tty=$(find_claude_tty)

if [[ -n "$target_tty" && -w "$target_tty" ]]; then
    printf '\a' > "$target_tty" 2>/dev/null
fi
