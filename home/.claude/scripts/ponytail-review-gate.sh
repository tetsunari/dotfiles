#!/usr/bin/env bash
# PreToolUse / UserPromptExpansion hook: code-review・codex-pr-review の前に /ponytail-review の実行を要求する
# 実行済み判定はセッション transcript に ponytail-review の呼び出し記録があるか（その後の編集有無は見ない）
# jq 不在時は素通し（fail-open）。transcript 未作成（セッション最初の入力）は未実行として扱う
set -uo pipefail

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null) || exit 0

case "$EVENT" in
  PreToolUse)
    TARGET=$(echo "$INPUT" | jq -r '.tool_input.skill // .tool_input.subagent_type // ""') ;;
  UserPromptExpansion)
    TARGET=$(echo "$INPUT" | jq -r '.command_name // ""') ;;
  *) exit 0 ;;
esac

case "$TARGET" in
  code-review|codex-pr-review) ;;
  *) exit 0 ;;
esac

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# [w] は hook 編集時に本パターン自体が transcript に載って誤判定するのを防ぐ
if [[ -f "$TRANSCRIPT" ]] && command grep -qE '"skill":"ponytail-revie[w]"|<command-name>/ponytail-revie[w]</command-name>' "$TRANSCRIPT"; then
  exit 0
fi

echo "先に /ponytail-review を実行すること（ponytail-review → 採否判断・修正 → ${TARGET} の順）" >&2
exit 2
