#!/usr/bin/env bash
# inject-lessons.py の単体テスト。fixtureのlessonsディレクトリで注入判定を検証する
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/inject-lessons.py"
FIXTURE_DIR=$(mktemp -d)
STATE_FIXTURE=$(mktemp -d)
trap 'rm -rf "$FIXTURE_DIR" "$STATE_FIXTURE"' EXIT

# レア語(zzzunique)を見出しに持つセクションと、無関係セクションを用意する。
# スコアは log(N/df) ベースなので、判定にはある程度のセクション数が要る。
{
  echo "# テスト用フィクスチャ"
  echo
  echo "### zzzunique な設定を変更するときの注意（テスト用）"
  echo "**count:** 1"
  echo "**ルール:** zzzunique のテスト用ルール本文"
  echo "**適用:** テスト用"
  echo
} > "$FIXTURE_DIR/target.md"

for i in $(seq 1 60); do
  {
    echo "### 無関係なルール$i（テスト用）"
    echo "**count:** 1"
    echo "**ルール:** 無関係な本文$i"
    echo "**適用:** テスト用"
    echo
  } >> "$FIXTURE_DIR/noise.md"
done

PASS=0
FAIL=0

# $1=説明 $2=プロンプト $3=期待する種別(body|index|none)
run_case() {
  local desc="$1" prompt="$2" expected="$3"
  local out actual
  out=$(printf '%s' "{\"prompt\":$(printf '%s' "$prompt" | jq -Rs .)}" \
    | INJECT_LESSONS_DIR="$FIXTURE_DIR" INJECT_STATE_DIR="$STATE_FIXTURE" "$HOOK" 2>/dev/null)
  if [[ -z "$out" ]]; then
    actual="none"
  else
    local ctx
    ctx=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext // empty')
    if [[ "$ctx" == 【学習済みルール索引* ]]; then actual="index"
    elif [[ "$ctx" == *"【関連しそうな学習済みルール】"* ]]; then actual="body"
    else actual="other"; fi
  fi
  if [[ "$actual" == "$expected" ]]; then
    echo "PASS: $desc"; PASS=$((PASS+1))
  else
    echo "FAIL: $desc (expected=$expected actual=$actual)"; FAIL=$((FAIL+1))
  fi
}

echo "--- 関連度による本文注入 / 索引フォールバック ---"
run_case "レア語が見出しに一致すれば本文を注入" "zzzunique の設定を変更したい" "body"
run_case "無関係な短文は索引にフォールバック" "やる" "index"
run_case "相槌だけでも索引は返す" "全部残す" "index"
run_case "空プロンプトは注入しない" "" "none"

echo "--- サイズ上限 ---"
BIG=$(printf 'zzzunique %.0s' $(seq 1 500))
run_case "長大プロンプトでも本文注入は成立する" "$BIG" "body"
SIZE=$(printf '%s' "{\"prompt\":$(printf '%s' "zzzunique の設定" | jq -Rs .)}" \
  | INJECT_LESSONS_DIR="$FIXTURE_DIR" INJECT_STATE_DIR="$STATE_FIXTURE" "$HOOK" \
  | jq -r '.hookSpecificOutput.additionalContext' | wc -c)
if (( SIZE <= 6500 )); then
  echo "PASS: 注入サイズが上限内 (${SIZE}B <= 6500B)"; PASS=$((PASS+1))
else
  echo "FAIL: 注入サイズが上限超過 (${SIZE}B)"; FAIL=$((FAIL+1))
fi

echo "--- remember-nudge の pending 回収 ---"
printf '%s' "テスト用の判定結果" > "$STATE_FIXTURE/remember-nudge.pending"
OUT=$(printf '%s' '{"prompt":"やる"}' \
  | INJECT_LESSONS_DIR="$FIXTURE_DIR" INJECT_STATE_DIR="$STATE_FIXTURE" "$HOOK" \
  | jq -r '.hookSpecificOutput.additionalContext')
if [[ "$OUT" == *"テスト用の判定結果"* ]]; then
  echo "PASS: pending が注入に含まれる"; PASS=$((PASS+1))
else
  echo "FAIL: pending が注入に含まれない"; FAIL=$((FAIL+1))
fi
if [[ ! -f "$STATE_FIXTURE/remember-nudge.pending" ]]; then
  echo "PASS: 回収後に pending が削除される"; PASS=$((PASS+1))
else
  echo "FAIL: pending が残存している"; FAIL=$((FAIL+1))
fi

printf '%s' "古い判定結果" > "$STATE_FIXTURE/remember-nudge.pending"
touch -d '2 hours ago' "$STATE_FIXTURE/remember-nudge.pending"
OUT=$(printf '%s' '{"prompt":"やる"}' \
  | INJECT_LESSONS_DIR="$FIXTURE_DIR" INJECT_STATE_DIR="$STATE_FIXTURE" "$HOOK" \
  | jq -r '.hookSpecificOutput.additionalContext')
if [[ "$OUT" != *"古い判定結果"* ]]; then
  echo "PASS: 期限切れ pending は破棄される"; PASS=$((PASS+1))
else
  echo "FAIL: 期限切れ pending が注入された"; FAIL=$((FAIL+1))
fi

echo "--- 異常入力でも落ちない ---"
for bad in 'garbage' '' '{"prompt":null}' '{}'; do
  if printf '%s' "$bad" | INJECT_LESSONS_DIR="$FIXTURE_DIR" INJECT_STATE_DIR="$STATE_FIXTURE" "$HOOK" >/dev/null 2>&1; then
    echo "PASS: 異常入力を安全に無視 [${bad:-空}]"; PASS=$((PASS+1))
  else
    echo "FAIL: 異常入力で非0終了 [${bad:-空}]"; FAIL=$((FAIL+1))
  fi
done

echo
echo "PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]]
