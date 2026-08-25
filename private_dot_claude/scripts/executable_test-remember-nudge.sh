#!/usr/bin/env bash
# remember-nudge.sh の単体テスト。transcript の fixture と claude スタブで
# 「判定に回すか否か」のフィルタと、pending 書き出しを検証する
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/remember-nudge.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# claude のスタブ。呼ばれたら呼び出し記録を残し、指定の判定を返す
STUB="$WORK/claude-stub"
cat > "$STUB" <<'EOF'
#!/usr/bin/env bash
echo called >> "$NUDGE_STATE_DIR/stub-calls"
printf '%s' "${STUB_JUDGMENT:-NO}"
EOF
chmod +x "$STUB"

PASS=0
FAIL=0

# transcript(jsonl)を組み立てる。$1=ユーザー発言 $2=Claude応答
make_transcript() {
  local t="$WORK/transcript.jsonl"
  : > "$t"
  jq -nc --arg u "$1" '{type:"user",message:{content:$u}}' >> "$t"
  jq -nc --arg a "$2" '{type:"assistant",message:{content:[{type:"text",text:$a}]}}' >> "$t"
  printf '%s' "$t"
}

# $1=説明 $2=ユーザー発言 $3=Claude応答 $4=期待(called|skipped)
run_case() {
  local desc="$1" user="$2" assistant="$3" expected="$4"
  local state t actual
  state=$(mktemp -d "$WORK/state.XXXXXX")
  t=$(make_transcript "$user" "$assistant")
  printf '%s' "{\"transcript_path\":\"$t\",\"stop_hook_active\":false}" \
    | NUDGE_STATE_DIR="$state" NUDGE_CLAUDE_BIN="$STUB" STUB_JUDGMENT="NO" "$HOOK" >/dev/null 2>&1
  # 非同期判定の完了を待つ
  for _ in $(seq 1 40); do [[ -f "$state/stub-calls" ]] && break; sleep 0.05; done
  [[ -f "$state/stub-calls" ]] && actual="called" || actual="skipped"
  if [[ "$actual" == "$expected" ]]; then
    echo "PASS: $desc"; PASS=$((PASS+1))
  else
    echo "FAIL: $desc (expected=$expected actual=$actual)"; FAIL=$((FAIL+1))
  fi
}

echo "--- 回答待ちで終わる応答は判定しない ---"
run_case "y/n 待ちは判定しない" "計画を出して" "この内容で実行していい？ (y/n)" "skipped"
run_case "疑問符終端は判定しない" "どうする" "この方針でええか？" "skipped"
run_case "最終行に疑問符を含めば判定しない" "整理して" "どれを残す？（個別指定でもOK）" "skipped"
run_case "既に提案済みなら判定しない" "直して" "この指摘を /remember で記録しますか" "skipped"

echo "--- 短い相槌・承認は判定しない(API呼び出し削減) ---"
run_case "短い承認は判定しない" "全部残す" "対応した。" "skipped"
run_case "短い指示は判定しない" "やる" "完了した。" "skipped"
run_case "短くても訂正シグナルがあれば判定する" "そこ間違い" "修正した。" "called"

echo "--- 通常のターンは判定に回す ---"
run_case "長い依頼は判定に回す" \
  "hookの挙動を調べて原因を特定し、修正方針をまとめてほしい" "調査して修正した。" "called"

echo "--- 判定結果が pending に書かれる ---"
STATE=$(mktemp -d "$WORK/state.XXXXXX")
T=$(make_transcript "hookの挙動を調べて原因を特定し、修正方針をまとめてほしい" "調査して修正した。")
printf '%s' "{\"transcript_path\":\"$T\",\"stop_hook_active\":false}" \
  | NUDGE_STATE_DIR="$STATE" NUDGE_CLAUDE_BIN="$STUB" STUB_JUDGMENT="YES" "$HOOK" >/dev/null 2>&1
for _ in $(seq 1 40); do [[ -f "$STATE/remember-nudge.pending" ]] && break; sleep 0.05; done
if [[ -f "$STATE/remember-nudge.pending" ]]; then
  echo "PASS: YES判定で pending が作られる"; PASS=$((PASS+1))
else
  echo "FAIL: YES判定でも pending が作られない"; FAIL=$((FAIL+1))
fi

STATE=$(mktemp -d "$WORK/state.XXXXXX")
printf '%s' "{\"transcript_path\":\"$T\",\"stop_hook_active\":false}" \
  | NUDGE_STATE_DIR="$STATE" NUDGE_CLAUDE_BIN="$STUB" STUB_JUDGMENT="NO" "$HOOK" >/dev/null 2>&1
for _ in $(seq 1 40); do [[ -f "$STATE/stub-calls" ]] && break; sleep 0.05; done
sleep 0.2
if [[ ! -f "$STATE/remember-nudge.pending" ]]; then
  echo "PASS: NO判定では pending を作らない"; PASS=$((PASS+1))
else
  echo "FAIL: NO判定なのに pending が作られた"; FAIL=$((FAIL+1))
fi

echo "--- Stop hook 自体は即座に返る(非同期化の検証) ---"
STATE=$(mktemp -d "$WORK/state.XXXXXX")
SLOW="$WORK/claude-slow"
cat > "$SLOW" <<'EOF'
#!/usr/bin/env bash
sleep 3
printf '%s' "NO"
EOF
chmod +x "$SLOW"
START=$(date +%s%N)
printf '%s' "{\"transcript_path\":\"$T\",\"stop_hook_active\":false}" \
  | NUDGE_STATE_DIR="$STATE" NUDGE_CLAUDE_BIN="$SLOW" "$HOOK" >/dev/null 2>&1
ELAPSED_MS=$(( ($(date +%s%N) - START) / 1000000 ))
if (( ELAPSED_MS < 1000 )); then
  echo "PASS: 判定に3秒かかっても hook は ${ELAPSED_MS}ms で返る"; PASS=$((PASS+1))
else
  echo "FAIL: hook がブロックしている (${ELAPSED_MS}ms)"; FAIL=$((FAIL+1))
fi

echo "--- 再帰防止 ---"
STATE=$(mktemp -d "$WORK/state.XXXXXX")
printf '%s' "{\"transcript_path\":\"$T\",\"stop_hook_active\":false}" \
  | CLAUDE_REMEMBER_NUDGE_ACTIVE=1 NUDGE_STATE_DIR="$STATE" NUDGE_CLAUDE_BIN="$STUB" "$HOOK" >/dev/null 2>&1
sleep 0.2
if [[ ! -f "$STATE/stub-calls" ]]; then
  echo "PASS: ネスト実行時は判定しない"; PASS=$((PASS+1))
else
  echo "FAIL: ネスト実行で再帰した"; FAIL=$((FAIL+1))
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]]
