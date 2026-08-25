#!/bin/bash
# 連続探索検出フック: Read/Grep/Glob が3回以上続いたら委譲警告を出す
COUNTER_FILE="/tmp/claude_explore_guard"
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")

case "$TOOL_NAME" in
  Read|Grep|Glob)
    count=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
    count=$((count + 1))
    echo "$count" > "$COUNTER_FILE"

    if [ "$count" -ge 3 ]; then
      echo "⚠️ [exploration-guard] 連続探索 ${count} 回を検出。"
      echo "広範な調査は code-explore エージェントへ委譲してください（delegation.md ルール）。"
      echo "自身での連続 Read/Grep/Glob は長考フリーズの原因になります。"
    fi
    ;;
  Agent|Write|Edit)
    echo "0" > "$COUNTER_FILE"
    ;;
esac

exit 0
