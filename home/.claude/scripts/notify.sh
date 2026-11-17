#!/bin/bash
# =============================================================================
# Claude Code notification script
# macOS: osascriptでネイティブ通知を送信（WezTermがフォーカス中は抑制）
# WSL2 : BELを送信 → WezTerm Luaでフォーカス判定して通知
# =============================================================================

# Stop 時に鳴らさない条件は2つ。権限確認（PermissionRequest）は対象外で、常に鳴らす。
# 1. herdr 配下（HERDR_ENV=1）: herdr 自身が完了通知を出すので、鳴らすと二重に届く。
# 2. サブエージェントが実行中: 1体戻るたびに親が再開→Stop するため、並列実行で通知が連発する。
#    最後の1体が戻った後の Stop（一覧から subagent が消えている）で1回だけ鳴る。
#    teammate は待機中も running のまま残り、shell は常駐プロセスがあり得るので判定に含めない。
# jq の失敗時は従来どおり鳴らす。
if [[ ! -t 0 ]] && jq -e --arg herdr "${HERDR_ENV:-}" '.hook_event_name == "Stop" and ($herdr == "1" or any(.background_tasks[]?; .type == "subagent" and .status == "running"))' >/dev/null 2>&1; then
    exit 0
fi

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
