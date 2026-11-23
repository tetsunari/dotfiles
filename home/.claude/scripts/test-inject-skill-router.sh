#!/usr/bin/env bash
# inject-skill-router.py の判定ロジック検証。
# hook は「発火しなかった」ことが正常系と区別できないため、
# 発火すべきケースと抑制すべきケースの両方を通す。
set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/inject-skill-router.py"
pass=0
fail=0

# run <期待するスキル名 or "-"> <プロンプト>
run() {
  local expect="$1" prompt="$2" out
  out=$(printf '%s' "$prompt" | python3 -c '
import json,sys
print(json.dumps({"prompt": sys.stdin.read()}))
' | "$SCRIPT" 2>&1)

  if [ "$expect" = "-" ]; then
    if [ -z "$out" ]; then
      pass=$((pass + 1)); printf "  ok   (抑制) %s\n" "$prompt"
    else
      fail=$((fail + 1)); printf "  FAIL (抑制されず) %s\n    -> %s\n" "$prompt" "$out"
    fi
  else
    if printf '%s' "$out" | grep -q "\`$expect\`"; then
      pass=$((pass + 1)); printf "  ok   (%s) %s\n" "$expect" "$prompt"
    else
      fail=$((fail + 1)); printf "  FAIL (%s が出ない) %s\n    -> %s\n" "$expect" "$prompt" "$out"
    fi
  fi
}

echo "== 発火すべきケース =="
run diagnosing-bugs        "ビルドがエラーで落ちるんだけど原因を調べて"
run diagnosing-bugs        "このAPIが遅くなったので調査して"
run diagnosing-bugs        "Fix this stack trace please"
run tdd                    "この関数のテストを書いて"
run tdd                    "TDDで進めたい"
run tdd                    "ついでにテストも書きたい"
run tdd                    "テストコードを追加してほしい"
run resolving-merge-conflicts "rebase中にコンフリクトが出た"
run resolving-merge-conflicts "resolve the merge conflict in main.ts"
run tidying                "このコードが汚いので整理して"
run task-planner           "新機能の実装計画を立てて"
run evidence-based         "たぶんこの仕様のはずだから実装しちゃっていい？"
run security-review        "ログイン認証を追加したい"
run cdk-infrastructure     "CDKのスタック間参照を変えたい"
run close-the-gap          "いい感じに作っといて"
run code-naming            "この関数の名前どうする？"
run code-naming            "変数名を考えて"
run codebase-design        "責務が混ざってるのでモジュール分割したい"
run handoff                "別セッションで続きをやるので引き継ぎを残して"
run explainer              "この設計を図解してわかりやすくして"
run explainer              "この PR の速習資料を作って"
run codex-plan-review      "実装計画の穴を探して"
run codex-pr-review        "差分をレビューして"
run codex-pr-review        "codex reviewを回して"

echo "== 英単語の直後が日本語でも境界が成立すること（\\b 罠の回帰） =="
run tdd                    "TDDで進めたい"
run cdk-infrastructure     "cdkでデプロイしたい"
run diagnosing-bugs        "debugしたい"
run resolving-merge-conflicts "conflictを解消して"
run security-review        "authの実装をお願い"
run tidying                "refactorしておいて"
run grill-mi               "grillして"

echo "== 抑制すべきケース（相槌・無関係） =="
run - "y"
run - "はい"
run - "OK"
run - "今日の天気は？"
run - "READMEに一行足して"
run - "ありがとう、助かった"

echo "== 無効スキルは注入しない（off の検証） =="
tmp_settings=$(mktemp)
printf '{"skillOverrides":{"tdd":"off"}}' > "$tmp_settings"
out=$(printf '{"prompt":"この関数のテストを書いて"}' | SKILL_ROUTER_SETTINGS="$tmp_settings" "$SCRIPT" 2>&1)
if printf '%s' "$out" | grep -q 'tdd'; then
  fail=$((fail + 1)); printf "  FAIL off のはずの tdd が注入された\n    -> %s\n" "$out"
else
  pass=$((pass + 1)); printf "  ok   off のスキルは注入されない\n"
fi
rm -f "$tmp_settings"

echo "== 実在しないスキルは注入しない =="
tmp_routes=$(mktemp)
printf '{"routes":[{"skill":"no-such-skill","reason":"x","patterns":["テスト"]}]}' > "$tmp_routes"
out=$(printf '{"prompt":"テストを書いて"}' | SKILL_ROUTER_FILE="$tmp_routes" "$SCRIPT" 2>&1)
if [ -z "$out" ]; then
  pass=$((pass + 1)); printf "  ok   実在しないスキルは注入されない\n"
else
  fail=$((fail + 1)); printf "  FAIL 実在しないスキルが注入された\n    -> %s\n" "$out"
fi
rm -f "$tmp_routes"

echo "== 壊れた入力でも落ちない =="
for bad in 'not json' '{}' '{"prompt":null}'; do
  if printf '%s' "$bad" | "$SCRIPT" >/dev/null 2>&1; then
    pass=$((pass + 1)); printf "  ok   異常入力を無害に処理: %s\n" "$bad"
  else
    fail=$((fail + 1)); printf "  FAIL 異常入力で異常終了: %s\n" "$bad"
  fi
done

printf "\n結果: pass=%d fail=%d\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
