#!/usr/bin/env bash
# Stop hook: 直近ターンに /remember 提案漏れがないかhaikuで判定する。
# 判定は同期実行すると毎ターン数秒のブロッキングになるため(実測3.7〜6.2秒)、
# バックグラウンドへ投げて即座に終了し、結果は次ターンの UserPromptSubmit hook
# (inject-lessons.py)が pending ファイルを拾って通知する。
set -euo pipefail

export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"

STATE_DIR="${NUDGE_STATE_DIR:-$HOME/.claude/state}"
PENDING="$STATE_DIR/remember-nudge.pending"
# 判定コマンド。テストからスタブに差し替えられるようにする(test-remember-nudge.sh)
NUDGE_CLAUDE_BIN="${NUDGE_CLAUDE_BIN:-claude}"

# ネスト実行(このスクリプトが呼ぶ claude -p 自体のStop hook)による無限再帰を防ぐ
[[ -n "${CLAUDE_REMEMBER_NUDGE_ACTIVE:-}" ]] && exit 0

INPUT=$(cat)
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')
STOP_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // "false"')

[[ "$STOP_ACTIVE" == "true" ]] && exit 0
[[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]] && exit 0

TURN=$(jq -s '
  . as $all
  | ( [ range(0;length) | select(
        $all[.].type=="user" and (
          ($all[.].message.content|type)=="string" or
          (($all[.].message.content|type)=="array" and ([$all[.].message.content[] | select(.type=="text")] | length > 0))
        )
      ) ] | last ) as $ui
  | ($all[$ui].message.content | if type=="string" then . else ([.[] | select(.type=="text").text]|join("\n")) end) as $user_text
  | ( [ $all[($ui+1):][] | select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text ] | join("\n") ) as $assistant_text
  | {user: $user_text, assistant: $assistant_text}
' "$TRANSCRIPT" 2>/dev/null) || exit 0

USER_TEXT=$(printf '%s' "$TURN" | jq -r '.user // empty' 2>/dev/null) || exit 0
ASSISTANT_TEXT=$(printf '%s' "$TURN" | jq -r '.assistant // empty' 2>/dev/null) || exit 0

[[ -z "$USER_TEXT" && -z "$ASSISTANT_TEXT" ]] && exit 0

# 既に/remember提案済みなら判定不要(定型の提案文言のみで判定し、単なる/remember言及と区別する)
[[ "$ASSISTANT_TEXT" == *"remember で記録"* ]] && exit 0

# ユーザーの回答待ち(y/n・承認確認・質問)で終わっている場合は判定しない。
# 作業はまだ途中であり、記録すべき学びは確定していない。ここで割り込むと
# ユーザーが回答したい問いが /remember 提案に置き換わってしまう。
# 末尾3行でy/n待ちを、最終行で疑問符終端を見る(本文中の疑問符での誤爆を避けるため)
TAIL3=$(printf '%s' "$ASSISTANT_TEXT" | grep -v '^[[:space:]]*$' | tail -3 || true)
LAST_LINE=$(printf '%s' "$TAIL3" | tail -1 || true)
if [[ "$TAIL3" =~ [yY]/[nN] ]] || [[ "$LAST_LINE" == *'?'* ]] || [[ "$LAST_LINE" == *'？'* ]]; then
  exit 0
fi

# 短い相槌・承認("y" "やる" "全部残す"等)だけのターンは記録すべき学びを含み得ないため
# 判定を省く(API呼び出しとコストの削減)。ただし短くても訂正・指示のシグナル語が
# あれば判定に回す。
if (( ${#USER_TEXT} < 20 )) && ! [[ "$USER_TEXT" =~ 違|間違|誤|ミス|ダメ|駄目|やめ|バグ|エラー|失敗|修正|直|覚え|記録|メモ ]]; then
  exit 0
fi

PROMPT=$(cat <<EOF
以下はユーザー発言とClaude応答のペアです。
1) ユーザーが訂正・否定・不満を述べた
2) ユーザーが明示的に「覚えて」「記録して」と言った
3) Claudeが作業中に「この知識があれば最初からミスしなかった」と自覚する形跡がある
のいずれかに該当するのに、Claude応答内に /remember 提案の言及が無い場合のみ YES、それ以外は NO とだけ一語で答えてください。

【ユーザー発言】
${USER_TEXT}

【Claude応答】
${ASSISTANT_TEXT}
EOF
)

mkdir -p "$STATE_DIR"
PROMPT_FILE=$(mktemp "$STATE_DIR/nudge-prompt.XXXXXX")
printf '%s' "$PROMPT" > "$PROMPT_FILE"

# 判定はバックグラウンドで実行し、Stop hook 自体は即座に抜ける。
# --setting-sources "" --strict-mcp-config --system-prompt で hooks/MCP/CLAUDE.md を一切継承させない
# (継承させるとinject-lessons.py等の巻き込みやMCP接続でレイテンシ増大・出力形式が不安定化・ハングする問題があったため)
nohup bash -c '
  trap "rm -f \"$1\"" EXIT
  export CLAUDE_REMEMBER_NUDGE_ACTIVE=1
  J=$(timeout 20s "$3" -p "$(cat "$1")" --model haiku --output-format text \
    --setting-sources "" --strict-mcp-config \
    --system-prompt "あなたは分類器です。与えられた指示に厳密に従い、YESかNOの一語のみを出力してください。他の文章・説明・提案は一切書かないでください。" \
    2>/dev/null) || exit 0
  [[ "$J" == *YES* ]] && printf "%s" "直前のやり取りに /remember で記録すべき内容(訂正・明示指示・自覚した学び)が含まれている可能性があります。/remember提案をしていなければ、ユーザーに提案してください。" > "$2"
  exit 0
' _ "$PROMPT_FILE" "$PENDING" "$NUDGE_CLAUDE_BIN" >/dev/null 2>&1 &
disown 2>/dev/null || true

exit 0
