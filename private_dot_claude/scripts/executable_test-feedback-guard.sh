#!/usr/bin/env bash
# feedback-guard.sh の単体テスト。fixtureのlessonsディレクトリで判定ロジックを検証する
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/feedback-guard.sh"
FIXTURE_DIR=$(mktemp -d)
trap 'rm -rf "$FIXTURE_DIR"' EXIT

cat > "$FIXTURE_DIR/sample.md" <<'EOF'
# テスト用フィクスチャ

### warnレベルの例（テスト用）
**count:** 1
**enforce:** pre_bash
**pattern:** foo-warn
**ルール:** テスト用ルールA
**適用:** テスト用

### askレベルの例（テスト用）
**count:** 3
**enforce:** pre_bash
**pattern:** foo-ask
**ルール:** テスト用ルールB
**適用:** テスト用

### denyレベルの例（テスト用）
**count:** 5
**enforce:** pre_bash
**pattern:** foo-deny
**ルール:** テスト用ルールC
**適用:** テスト用

### pre_editの例（テスト用）
**count:** 2
**enforce:** pre_edit
**pattern:** bar-edit
**ルール:** テスト用ルールD
**適用:** テスト用
EOF

PASS=0
FAIL=0

run_case() {
  local desc="$1" input="$2" expected="$3"
  local actual
  actual=$(echo "$input" | FEEDBACK_LESSONS_DIR="$FIXTURE_DIR" "$GUARD" 2>/dev/null | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
  [[ -z "$actual" ]] && actual="allow"
  if [[ "$actual" == "$expected" ]]; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc (expected=$expected actual=$actual)"
    FAIL=$((FAIL+1))
  fi
}

run_case "warn(count=1)は許可" \
  '{"tool_name":"Bash","tool_input":{"command":"run foo-warn now"}}' \
  "allow"

run_case "ask(count=3)は確認" \
  '{"tool_name":"Bash","tool_input":{"command":"run foo-ask now"}}' \
  "ask"

run_case "deny(count=5)は拒否" \
  '{"tool_name":"Bash","tool_input":{"command":"run foo-deny now"}}' \
  "deny"

run_case "pre_edit(count=2)は許可" \
  '{"tool_name":"Edit","tool_input":{"file_path":"x.ts","new_string":"bar-edit-content"}}' \
  "allow"

run_case "マッチなしは許可" \
  '{"tool_name":"Bash","tool_input":{"command":"echo hello"}}' \
  "allow"

echo "---"
echo "PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]]
