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
  echo "### zzzunique zzzalpha zzzbeta zzzgamma な設定を変更するときの注意（テスト用）"
  echo "**count:** 1"
  echo "**ルール:** zzzunique のテスト用ルール本文"
  echo "**適用:** テスト用"
  echo
} > "$FIXTURE_DIR/target.md"

{
  echo "### zzzcodebuild の buildspec と zzzmod-x.py を直すときの注意（テスト用）"
  echo "**ルール:** 英字の境界判定用"
  echo
  echo "### 蠍座星雲を観る手順（テスト用）"
  echo "**ルール:** 漢字 2gram 判定用"
  echo
} > "$FIXTURE_DIR/boundary.md"

# 直前の assistant 発言を模した transcript。1行目は tail 読みで切れた行を模す
RICH_TRANSCRIPT="$STATE_FIXTURE/rich.jsonl"
{
  echo 'ken":"切れた行"}'
  jq -nc '{type:"user",message:{role:"user",content:"zzzdelta"}}'
  jq -nc '{type:"assistant",message:{role:"assistant",content:[{type:"thinking",thinking:"無関係"}]}}'
  jq -nc '{type:"assistant",message:{role:"assistant",content:[{type:"text",text:"zzzalpha と zzzbeta を確認する"}]}}'
  jq -nc '{type:"assistant",message:{role:"assistant",content:[{type:"tool_use",name:"Bash",input:{command:"grep zzzgamma zzzunique"}}]}}'
  jq -nc '{type:"user",message:{role:"user",content:[{type:"tool_result",content:"ok"}]}}'
} > "$RICH_TRANSCRIPT"
WEAK_TRANSCRIPT="$STATE_FIXTURE/weak.jsonl"
jq -nc '{type:"assistant",message:{role:"assistant",content:[{type:"text",text:"zzzunique を見た"}]}}' > "$WEAK_TRANSCRIPT"

assistant_text() { jq -nc --arg t "$1" '{type:"assistant",message:{role:"assistant",content:[{type:"text",text:$t}]}}'; }
user_prompt() { jq -nc --arg t "$1" '{type:"user",message:{role:"user",content:$t}}'; }
tool_result() { jq -nc --arg t "$1" '{type:"user",message:{role:"user",content:[{type:"tool_result",content:$t}]}}'; }
STRONG="zzzalpha zzzbeta zzzgamma zzzunique"

OLD_TOPIC_TRANSCRIPT="$STATE_FIXTURE/old-topic.jsonl"
{ assistant_text "$STRONG"; user_prompt "別の話題"; assistant_text "了解"; } > "$OLD_TOPIC_TRANSCRIPT"
CURRENT_APPENDED_TRANSCRIPT="$STATE_FIXTURE/current-appended.jsonl"
{ assistant_text "$STRONG"; user_prompt "続けて"; } > "$CURRENT_APPENDED_TRANSCRIPT"
BIG_LINE_TRANSCRIPT="$STATE_FIXTURE/big-line.jsonl"
{ assistant_text "$STRONG"; tool_result "$(head -c 70000 /dev/zero | tr '\0' a)"; } > "$BIG_LINE_TRANSCRIPT"
BAD_TYPES_TRANSCRIPT="$STATE_FIXTURE/bad-types.jsonl"
{
  assistant_text "$STRONG"
  jq -nc '{type:"assistant",message:{content:[{type:"text",text:null}]}}'
  jq -nc '{type:"assistant",message:{content:[null]}}'
  jq -nc '{type:"assistant",message:{content:[{type:"tool_use",input:"文字列"}]}}'
} > "$BAD_TYPES_TRANSCRIPT"
LINE_SEPARATOR_TRANSCRIPT="$STATE_FIXTURE/line-separator.jsonl"
assistant_text $'zzzalpha zzzbeta zzzgamma zzzunique' > "$LINE_SEPARATOR_TRANSCRIPT"
EXCLUDED_TRANSCRIPT="$STATE_FIXTURE/excluded.jsonl"
{
  jq -nc --arg t "$STRONG" '{type:"assistant",message:{content:[{type:"thinking",thinking:$t}]}}'
  tool_result "$STRONG"
} > "$EXCLUDED_TRANSCRIPT"

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

# $1=説明 $2=プロンプト $3=期待する種別(body|index|none) $4=transcript_path(省略可)
run_case() {
  local desc="$1" prompt="$2" expected="$3" transcript="${4:-}"
  local out actual
  out=$(jq -nc --arg p "$prompt" --arg t "$transcript" \
      '{prompt:$p} + (if $t == "" then {} else {transcript_path:$t} end)' \
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

echo "--- 通知のターン ---"
run_case "バックグラウンド完了通知では注入しない" \
  $'<task-notification>\n<summary>zzzunique completed (exit code 0)</summary>\n</task-notification>' "none"
run_case "SYSTEM NOTIFICATION では注入しない" "[SYSTEM NOTIFICATION] zzzunique done" "none"
run_case "サブエージェントの報告では注入しない" "Another Claude session sent a message: zzzunique" "none"
run_case "agent-message では注入しない" "<agent-message>zzzunique</agent-message>" "none"
run_case "本文の途中に通知タグがある通常の入力は注入する" "zzzunique の <task-notification> を調べる" "body"

echo "--- 直前のやり取りを材料にする ---"
run_case "短い入力でも直前の発言が関連すれば本文を注入" "続けて" "body" "$RICH_TRANSCRIPT"
run_case "直前の発言の一致が弱ければ索引のまま" "続けて" "index" "$WEAK_TRANSCRIPT"
run_case "transcript が無くても落ちない" "続けて" "index" "$STATE_FIXTURE/nonexistent.jsonl"
run_case "前のユーザー入力より古い発言は材料にしない" "続けて" "index" "$OLD_TOPIC_TRANSCRIPT"
run_case "今回の入力が transcript に書かれていても直前の発言を拾う" "続けて" "body" "$CURRENT_APPENDED_TRANSCRIPT"
run_case "64KB を超える行が末尾にあっても直前の発言を拾う" "続けて" "body" "$BIG_LINE_TRANSCRIPT"
run_case "型が想定外のブロックは飛ばして残りを使う" "続けて" "body" "$BAD_TYPES_TRANSCRIPT"
run_case "U+2028 を含む行も1行として読む" "続けて" "body" "$LINE_SEPARATOR_TRANSCRIPT"
run_case "thinking とツールの結果は材料にしない" "続けて" "index" "$EXCLUDED_TRANSCRIPT"
CTX=$(jq -nc --arg t "$RICH_TRANSCRIPT" '{prompt:"zzzcodebuild を直す",transcript_path:$t}' \
  | INJECT_LESSONS_DIR="$FIXTURE_DIR" INJECT_STATE_DIR="$STATE_FIXTURE" "$HOOK" \
  | jq -r '.hookSpecificOutput.additionalContext // empty')
if [[ "$CTX" == *"zzzcodebuild"* && "$CTX" != *"zzzalpha"* ]]; then
  echo "PASS: 入力だけで関連が決まるときは直前の発言で結果を変えない"; PASS=$((PASS+1))
else
  echo "FAIL: 直前の発言の教訓が入力の教訓に混ざった"; FAIL=$((FAIL+1))
fi

echo "--- 英字は単語の境目で一致させる ---"
run_case "英字は語の一部には一致しない" "zzzcode が終わった" "index"
run_case "英字は語全体なら一致する（末尾の句点は無視）" "zzzcodebuild." "body"
run_case "英字はファイル名の一部にも語の境目で一致する" "zzzmod-x を直す" "body"
run_case "漢字は 2 文字切りで複合語を拾う" "星雲観測" "body"

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

printf '%s' "通知中の判定結果" > "$STATE_FIXTURE/remember-nudge.pending"
printf '%s' '{"prompt":"<task-notification>done</task-notification>"}' \
  | INJECT_LESSONS_DIR="$FIXTURE_DIR" INJECT_STATE_DIR="$STATE_FIXTURE" "$HOOK" >/dev/null
if [[ -f "$STATE_FIXTURE/remember-nudge.pending" ]]; then
  echo "PASS: 通知のターンでは pending を回収せず次の入力に残す"; PASS=$((PASS+1))
else
  echo "FAIL: 通知のターンで pending が消費された"; FAIL=$((FAIL+1))
fi

printf '%s' "古い判定結果" > "$STATE_FIXTURE/remember-nudge.pending"
# touch -d はGNU専用でmacOS(BSD)では失敗するため、python3でmtimeを2時間前にする
python3 -c 'import os, sys, time; t = time.time() - 7200; os.utime(sys.argv[1], (t, t))' "$STATE_FIXTURE/remember-nudge.pending"
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
