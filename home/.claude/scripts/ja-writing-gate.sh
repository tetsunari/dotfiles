#!/usr/bin/env bash
# PreToolUse(Bash) hook: gh pr create / gh pr ready / glab mr create の前に japanese-tech-writing の実行を要求する
# 実行済み判定はセッション transcript に japanese-tech-writing の呼び出し記録があるか（その後の本文変更は見ない）
# jq 不在時は素通し（fail-open）
set -uo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0

if ! echo "$CMD" | command grep -qE '(^|[^[:alnum:]_-])(gh[[:space:]]+pr[[:space:]]+(create|ready)|glab[[:space:]]+mr[[:space:]]+create)([^[:alnum:]_-]|$)'; then
  exit 0
fi

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')

# [g] は hook 編集時に本パターン自体が transcript に載って誤判定するのを防ぐ
if [[ -f "$TRANSCRIPT" ]] && command grep -qE '"skill":"japanese-tech-writin[g]"|<command-name>/japanese-tech-writin[g]</command-name>' "$TRANSCRIPT"; then
  exit 0
fi

echo "先に japanese-tech-writing スキルで PR/MR のタイトルと本文を推敲すること（「LLM っぽい表現の禁止」「冗長の排除」の節を当てる）" >&2
exit 2
