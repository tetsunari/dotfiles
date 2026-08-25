#!/usr/bin/env bash
# PreToolUse hook: lessonsのcountに応じてBash/Edit実行をwarn/ask/denyする
# rg/grepの「不一致(非0終了)」を正常系として使うため -e は付けない
set -uo pipefail
export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null) || exit 0

case "$TOOL_NAME" in
  Bash) ENFORCE_TYPE="pre_bash" ;;
  Edit|Write) ENFORCE_TYPE="pre_edit" ;;
  *) exit 0 ;;
esac

TOOL_INPUT_STR=$(echo "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null) || exit 0

LESSONS_DIR="${FEEDBACK_LESSONS_DIR:-$HOME/.config/claude/lessons}"
[[ -d "$LESSONS_DIR" ]] || exit 0

BEST_COUNT=-1
BEST_HEADING=""
BEST_RULE=""

CUR_HEADING=""
CUR_COUNT=""
CUR_ENFORCE=""
CUR_PATTERN=""
CUR_RULE=""

flush_entry() {
  [[ "$CUR_ENFORCE" == "$ENFORCE_TYPE" ]] || return 0
  [[ -n "$CUR_PATTERN" ]] || return 0
  if echo "$TOOL_INPUT_STR" | rg -q -- "$CUR_PATTERN" 2>/dev/null; then
    if (( CUR_COUNT > BEST_COUNT )); then
      BEST_COUNT=$CUR_COUNT
      BEST_HEADING=$CUR_HEADING
      BEST_RULE=$CUR_RULE
    fi
  fi
}

while IFS= read -r -d '' file; do
  [[ -s "$file" ]] || continue

  CUR_HEADING=""; CUR_COUNT=""; CUR_ENFORCE=""; CUR_PATTERN=""; CUR_RULE=""

  while IFS= read -r line; do
    if [[ "$line" == "### "* ]]; then
      flush_entry
      CUR_HEADING="${line#"### "}"
      CUR_COUNT=""; CUR_ENFORCE=""; CUR_PATTERN=""; CUR_RULE=""
    elif [[ "$line" == "**count:**"* ]]; then
      CUR_COUNT="${line#"**count:** "}"
      CUR_COUNT="${CUR_COUNT//[^0-9]/}"
    elif [[ "$line" == "**enforce:**"* ]]; then
      CUR_ENFORCE="${line#"**enforce:** "}"
    elif [[ "$line" == "**pattern:**"* ]]; then
      CUR_PATTERN="${line#"**pattern:** "}"
    elif [[ "$line" == "**ルール:**"* && -z "$CUR_RULE" ]]; then
      CUR_RULE="${line#"**ルール:** "}"
    fi
  done < "$file"
  flush_entry
done < <(find "$LESSONS_DIR" -name "*.md" -print0 | sort -z)

[[ "$BEST_COUNT" -lt 0 ]] && exit 0

if (( BEST_COUNT <= 2 )); then
  DECISION="allow"
elif (( BEST_COUNT <= 4 )); then
  DECISION="ask"
else
  DECISION="deny"
fi

REASON="[feedback-guard] ${BEST_HEADING}(指摘${BEST_COUNT}回目): ${BEST_RULE}"

jq -n --arg decision "$DECISION" --arg reason "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: $decision,
    permissionDecisionReason: $reason
  }
}'
exit 0
