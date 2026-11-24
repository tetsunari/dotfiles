#!/bin/bash
# =============================================================================
# Claude Code notification script
# macOS: osascriptでネイティブ通知を送信（WezTermがフォーカス中は抑制）
# WSL2 : BELを送信 → WezTerm Luaでフォーカス判定して通知
# =============================================================================

# Stop 時に鳴らさない条件は2つ。権限確認（PermissionRequest）は対象外で、常に鳴らす。
# herdr の中でも鳴らす（herdr の通知は [ui.toast] delivery = "off" で切り、WezTerm 側で出している）。
# jq の失敗時は従来どおり鳴らす。
# 1. サブエージェントかバックグラウンドのシェルが実行中: まだ待っているだけで、終わったら再開して
#    もう一度 Stop する。そちらで1回だけ鳴る。dev サーバーなどの常駐プロセスが残っている間は鳴らない。
#    teammate は待機中も running のまま残るので判定に含めない。
# 2. ユーザーが ! で打ったシェルに Claude が返事しただけ: transcript の最後のユーザーの記録が
#    <bash-input> / <bash-stdout> になる。
HOOK_INPUT=""
[[ -t 0 ]] || HOOK_INPUT=$(cat)
if [[ "$(jq -r '.hook_event_name // empty' <<<"$HOOK_INPUT" 2>/dev/null)" == "Stop" ]]; then
    if jq -e 'any(.background_tasks[]?; (.type == "subagent" or .type == "shell") and .status == "running")' <<<"$HOOK_INPUT" >/dev/null 2>&1; then
        exit 0
    fi
    transcript=$(jq -r '.transcript_path // empty' <<<"$HOOK_INPUT" 2>/dev/null)
    if [[ -f "$transcript" ]] && jq -r 'select(.type == "user" and (.isSidechain | not) and (.isMeta | not)) | .message.content
                 | if type == "string" then . else ([.[]? | select(.type == "text") | .text] | join(" ")) end
                 | select(length > 0) | startswith("<bash-")' "$transcript" 2>/dev/null \
        | tail -n 1 | grep -qx true; then
        exit 0
    fi
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

# herdr の中では文言を WezTerm に渡せないので、文言とどの workspace / tab / pane かをファイルに書き、
# ベルを受けた WezTerm に読ませる（~/.config/wezterm/modules/notification.lua）。
# 1行目は書いた時刻（古いファイルを使わないため）。取れなかった名前は空のまま書く。
# 4行目は herdr でこのペインがフォーカス中か（true / false）。別の workspace・tab・ペインを見ている時は
# WezTerm 自体がフォーカス中でも気づけないので、WezTerm は false なら通知を出す。取れなければ空
HERDR_NOTIFY_FILE=/tmp/claude-herdr-notify.txt
write_herdr_notify() {
    command -v herdr >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 || return 0
    local workspace tab pane_json pane focused
    workspace=$(herdr workspace get "${HERDR_WORKSPACE_ID:-}" 2>/dev/null | jq -r '.result.workspace.label // empty')
    tab=$(herdr tab get "${HERDR_TAB_ID:-}" 2>/dev/null | jq -r '.result.tab.label // empty')
    pane_json=$(herdr pane get "${HERDR_PANE_ID:-}" 2>/dev/null)
    pane=$(jq -r '.result.pane.terminal_title_stripped // empty' <<<"$pane_json" 2>/dev/null)
    # `// empty` は false も空にするので使わない
    focused=$(jq -r '.result.pane.focused | select(. != null)' <<<"$pane_json" 2>/dev/null)
    printf '%s\n%s\n%s / tab %s / %s\n%s\n' "$(date +%s)" "$MESSAGE" "$workspace" "$tab" "$pane" "$focused" > "$HERDR_NOTIFY_FILE.tmp" \
        && mv "$HERDR_NOTIFY_FILE.tmp" "$HERDR_NOTIFY_FILE"
}

notify_wsl() {
    local target_tty
    target_tty=$(find_claude_tty)

    if [[ -n "$target_tty" && -w "$target_tty" ]]; then
        if [[ "${HERDR_ENV:-}" == "1" ]]; then
            # herdr は文言入りの通知をベルに変えて渡すので、文言はファイルで渡してベルだけ送る
            write_herdr_notify
            printf '\a' > "$target_tty" 2>/dev/null
        else
            # WezTerm に直接届くので、文言ごと送る（OSC 777）
            printf '\e]777;notify;%s;%s\e\\' "$TITLE" "$MESSAGE" > "$target_tty" 2>/dev/null
        fi
    fi
}

if [[ "$(uname -s)" == "Darwin" ]]; then
    notify_macos
else
    notify_wsl
fi
