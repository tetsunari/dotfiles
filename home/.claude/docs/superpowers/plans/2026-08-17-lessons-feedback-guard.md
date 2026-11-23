# lessons count付与 + feedback-guard hook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `~/.config/claude/lessons/`の全指摘エントリに`**count:**`（指摘回数）を付与し、行動規制型のパイロット4件については`**enforce:**`/`**pattern:**`を追加、countに応じてBash/Edit実行前にwarn→ask→denyする新規PreToolUse hook（`feedback-guard.sh`）を追加する。

**Architecture:** 既存の`### 見出し` + `**ルール:**` + `**適用:**`という慣習をプレーンなラベル行で延長する（YAML frontmatterや別registryファイルは導入しない）。新規hookは既存の`exploration-guard.sh`と同じ流儀（bash + jq + rg、matcher未指定でtool_name内部case分岐、fail-safe exit 0）で実装する。

**Tech Stack:** bash, jq, ripgrep(rg)。WSL(Ubuntu)上で動作。全コマンドは`wsl.exe -d Ubuntu -- zsh -ic '<command>'`経由で実行する（`~/.claude/rules/wsl-operations.md`準拠）。

## Global Constraints

- 対象ディレクトリ（`~/.claude`, `~/.config/claude`）はgit管理外。**commitステップは行わない**。各タスク末尾は検証ステップに置き換える
- 複数行スクリプトはWindows Bash→wsl.exe→zshの多重シェルでクォートが崩れるため、Writeツールで`\\wsl.localhost\Ubuntu\tmp\...`にスクリプトを書き出してから`wsl.exe -d Ubuntu -- zsh -ic 'bash /tmp/...'`で実行する（heredocを直接シェル経由で流さない）
- 既存hookスクリプトの規約（`set -euo pipefail`が基本だが、rg/grepの「不一致」を正常系として扱うスクリプトでは`-e`を外す）を踏襲する
- 新規hookは`~/.claude/settings.json`の`hooks.PreToolUse`配列に**既存`exploration-guard.sh`エントリとは別の要素として追加**する（既存エントリは変更しない）

---

### Task 1: lessonsファイルへの`**count:** 1`一括付与 + パイロット4件への`enforce`/`pattern`追加

**Files:**
- Create: `\\wsl.localhost\Ubuntu\tmp\migrate-lessons-count.sh`（一時スクリプト、使い捨て）
- Modify: `~/.config/claude/lessons/*.md`（19ファイル。`### `見出しを持たないファイル＝`lessons.md`, `architecture-investigation.md`は変化なし）
- Modify（個別Edit）:
  - `~/.config/claude/lessons/general.md`（2エントリ）
  - `~/.config/claude/lessons/code-style.md`（2エントリ）

**Interfaces:**
- Produces: 各`### `見出しの直後に`**count:** 1`行が入る。パイロット4件のみ`**count:** 1`の直後に`**enforce:** pre_bash|pre_edit`・`**pattern:** <regex>`が続く。Task 2はこのフォーマットを前提にパースする

- [ ] **Step 1: 移行前の状態を確認（検知確認）**

Run:
```bash
wsl.exe -d Ubuntu -- zsh -ic 'for f in ~/.config/claude/lessons/*.md; do c=$(grep -c "^\*\*count:\*\*" "$f" 2>/dev/null || echo 0); echo "$f count-lines=$c"; done'
```
Expected: 全ファイルで `count-lines=0`（まだ`**count:**`行が1件も存在しないことの確認＝これが「失敗する状態」の確認に相当する）

- [ ] **Step 2: 一括付与スクリプトを作成**

Write to `\\wsl.localhost\Ubuntu\tmp\migrate-lessons-count.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
LESSONS_DIR="$HOME/.config/claude/lessons"
for f in "$LESSONS_DIR"/*.md; do
  awk '
    { print }
    /^### / { print "**count:** 1" }
  ' "$f" > "$f.tmp"
  mv "$f.tmp" "$f"
done
echo "migration done"
```

- [ ] **Step 3: スクリプトを実行**

Run:
```bash
wsl.exe -d Ubuntu -- zsh -ic 'bash /tmp/migrate-lessons-count.sh'
```
Expected: `migration done` が出力される

- [ ] **Step 4: 見出し数とcount行数が一致することを検証**

Run:
```bash
wsl.exe -d Ubuntu -- zsh -ic 'for f in ~/.config/claude/lessons/*.md; do h=$(grep -c "^### " "$f" 2>/dev/null || echo 0); c=$(grep -c "^\*\*count:\*\* " "$f" 2>/dev/null || echo 0); if [ "$h" = "$c" ]; then echo "OK $f ($h)"; else echo "MISMATCH $f heading=$h count=$c"; fi; done'
```
Expected: 全行が`OK`で始まる。`MISMATCH`が1件でもあれば失敗

- [ ] **Step 5: 目視確認**

Read `\\wsl.localhost\Ubuntu\home\<user>\.config\claude\lessons\aws-network.md` と `code-style.md` を確認し、`**count:** 1`が各`### `見出し直後に挿入され、既存の`**ルール:**`等の行が壊れていないことを確認する

- [ ] **Step 6: パイロット4件に`enforce`/`pattern`を追加（general.md 1件目）**

Edit `\\wsl.localhost\Ubuntu\home\<user>\.config\claude\lessons\general.md`:

old_string:
```
### stash pop の衝突を `git checkout --theirs .` で解決しない（2026-07-27追記）
**count:** 1
**ルール:**
```

new_string:
```
### stash pop の衝突を `git checkout --theirs .` で解決しない（2026-07-27追記）
**count:** 1
**enforce:** pre_bash
**pattern:** checkout --theirs
**ルール:**
```

- [ ] **Step 7: パイロット4件（general.md 2件目）**

Edit `general.md`:

old_string:
```
### git stash 前は影響範囲を確認する（2026-07-28追記）
**count:** 1
**ルール:**
```

new_string:
```
### git stash 前は影響範囲を確認する（2026-07-28追記）
**count:** 1
**enforce:** pre_bash
**pattern:** git stash
**ルール:**
```

- [ ] **Step 8: パイロット4件（code-style.md 1件目）**

Edit `\\wsl.localhost\Ubuntu\home\<user>\.config\claude\lessons\code-style.md`:

old_string:
```
### private関数禁止（2026-06-08追記）
**count:** 1
**ルール:**
```

new_string:
```
### private関数禁止（2026-06-08追記）
**count:** 1
**enforce:** pre_edit
**pattern:** private 
**ルール:**
```

- [ ] **Step 9: パイロット4件（code-style.md 2件目）**

Edit `code-style.md`:

old_string:
```
### ARN から ID 抽出時の non-null assertion 禁止（2026-07-07追記）
**count:** 1
**ルール:**
```

new_string:
```
### ARN から ID 抽出時の non-null assertion 禁止（2026-07-07追記）
**count:** 1
**enforce:** pre_edit
**pattern:** \.pop\(\)!
**ルール:**
```

- [ ] **Step 10: パイロット4件が正しく追加されたことを検証**

Run:
```bash
wsl.exe -d Ubuntu -- zsh -ic 'grep -c "^\*\*enforce:\*\* " ~/.config/claude/lessons/*.md | grep -v ":0"'
```
Expected: `general.md:2` と `code-style.md:2` の2行のみ出力される

---

### Task 2: `feedback-guard.sh` の実装（テスト先行）

**Files:**
- Create: `\\wsl.localhost\Ubuntu\home\<user>\.claude\scripts\test-feedback-guard.sh`
- Create: `\\wsl.localhost\Ubuntu\home\<user>\.claude\scripts\feedback-guard.sh`

**Interfaces:**
- Consumes: Task 1で確立したlessonsエントリ形式（`### 見出し` → `**count:** N` → 任意で`**enforce:** pre_bash|pre_edit` + `**pattern:** <regex>` → `**ルール:** ...`）
- Consumes（stdin, PreToolUse hook入力）: `{"tool_name": "Bash"|"Edit"|"Write"|..., "tool_input": {...}}`
- Produces（stdout）: マッチ時のみ `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"|"ask"|"deny", "permissionDecisionReason": "<string>"}}`。マッチなし時は無出力・`exit 0`
- Produces（環境変数）: `FEEDBACK_LESSONS_DIR`が設定されていればデフォルトの`~/.config/claude/lessons`の代わりに使用する（テスト用フィクスチャ差し替え口）

- [ ] **Step 1: テストスクリプトを作成（この時点では対象スクリプトが存在せず失敗する）**

Write to `\\wsl.localhost\Ubuntu\home\<user>\.claude\scripts\test-feedback-guard.sh`:

```bash
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
```

- [ ] **Step 2: 実行して失敗することを確認**

Run:
```bash
wsl.exe -d Ubuntu -- zsh -ic 'chmod +x ~/.claude/scripts/test-feedback-guard.sh; ~/.claude/scripts/test-feedback-guard.sh'
```
Expected: `feedback-guard.sh: No such file or directory` 等のエラーで全ケースFAILする

- [ ] **Step 3: `feedback-guard.sh` を実装**

Write to `\\wsl.localhost\Ubuntu\home\<user>\.claude\scripts\feedback-guard.sh`:

```bash
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
```

- [ ] **Step 4: 実行権限を付与しテストを再実行、全PASSを確認**

Run:
```bash
wsl.exe -d Ubuntu -- zsh -ic 'chmod +x ~/.claude/scripts/feedback-guard.sh; ~/.claude/scripts/test-feedback-guard.sh'
```
Expected: 5ケース全て`PASS`、末尾`PASS=5 FAIL=0`

- [ ] **Step 5: 実データ（Task 1で移行した本物のlessons）に対するスモークテスト**

Run:
```bash
wsl.exe -d Ubuntu -- zsh -ic 'echo "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git checkout --theirs .\"}}" | ~/.claude/scripts/feedback-guard.sh | jq .'
```
Expected: `permissionDecision`が`"allow"`（count=1のため）、`permissionDecisionReason`に「stash pop の衝突を」を含む文字列が出力される

---

### Task 3: `settings.json` へのhook登録

**Files:**
- Modify: `\\wsl.localhost\Ubuntu\home\<user>\.claude\settings.json`

**Interfaces:**
- Consumes: Task 2で作成した`~/.claude/scripts/feedback-guard.sh`（実行可能であること）

- [ ] **Step 1: 現在のJSONが妥当であることを事前確認**

Run:
```bash
wsl.exe -d Ubuntu -- zsh -ic 'jq empty ~/.claude/settings.json && echo VALID_BEFORE'
```
Expected: `VALID_BEFORE`

- [ ] **Step 2: `PreToolUse`配列に新規エントリを追加**

Edit `\\wsl.localhost\Ubuntu\home\<user>\.claude\settings.json`:

old_string:
```
    "PreToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/exploration-guard.sh"
          }
        ]
      }
    ]
```

new_string:
```
    "PreToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/exploration-guard.sh"
          }
        ]
      },
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/feedback-guard.sh"
          }
        ]
      }
    ]
```

- [ ] **Step 3: JSON妥当性と内容を検証**

Run:
```bash
wsl.exe -d Ubuntu -- zsh -ic 'jq empty ~/.claude/settings.json && echo VALID_AFTER; jq ".hooks.PreToolUse | length" ~/.claude/settings.json'
```
Expected: `VALID_AFTER`、続けて`2`（PreToolUseの要素数が2になった）

- [ ] **Step 4: 手動確認事項をユーザーに提示（このセッション内では自動検証不可）**

hook設定は新規セッション起動時に読み込まれるため、今回のセッション内で`git checkout --theirs`等を実際に実行してもこのhookは発火しない。次回セッションで以下を手動確認するようユーザーに案内する:
- 新しいセッションで`Bash(git checkout --theirs .)`相当のコマンドを実行し、`allow`（警告表示）になること
- `private ` を含む内容でEdit/Writeを実行し、同様にallow表示されること

---

### Task 4: `/remember` スキルへのcount運用手順の統合

**Files:**
- Modify: `C:\Users\<win-user>\.claude\skills\remember\SKILL.md`

**Interfaces:**
- Produces: 今後`/remember`で新規追記されるエントリは`**count:** 1`から開始し、重複時は既存エントリの`**count:**`を+1する運用に変わる

- [ ] **Step 1: 「書き込みフォーマット」テンプレートに`**count:**`を追加**

Edit `C:\Users\<win-user>\.claude\skills\remember\SKILL.md`:

old_string:
```
```markdown
### {ルール名}（YYYY-MM-DD追記）
**ルール:** {具体的・行動可能なルール。「〜すること」「〜しないこと」で書く}
**適用:** {いつ・どのような状況で適用するか}
```
```

new_string:
```
```markdown
### {ルール名}（YYYY-MM-DD追記）
**count:** 1
**ルール:** {具体的・行動可能なルール。「〜すること」「〜しないこと」で書く}
**適用:** {いつ・どのような状況で適用するか}
```
```

- [ ] **Step 2: 重複時の運用を「count+1」に変更**

Edit `SKILL.md`:

old_string:
```
重複あり → 既存エントリを更新する
重複なし → ファイル末尾に追記する
```

new_string:
```
重複あり → 既存エントリの`**count:**`を+1し、必要なら内容を更新する
重複なし → ファイル末尾に追記する（`**count:** 1`から開始する）
```

- [ ] **Step 3: 変更内容を目視確認**

Read `C:\Users\<win-user>\.claude\skills\remember\SKILL.md` の該当2箇所が意図通り書き換わっていることを確認する

---

## Self-Review Notes

- **Spec coverage:** メタデータ形式（Task1,4）、パイロット4件（Task1）、feedback-guard.sh本体・判定閾値（Task2）、settings.json登録（Task3）、count運用の/remember統合（Task4）を全てカバー。設計docの「将来の拡張候補」（stop-check・inject重み付け・enforce追加）は意図的にスコープ外
- **Placeholder scan:** 全ステップに実コード・実コマンドを記載済み。TBD/TODO無し
- **Type consistency:** `permissionDecision`の値（allow/ask/deny）・`FEEDBACK_LESSONS_DIR`環境変数名・エントリのラベル行名（`**count:**`/`**enforce:**`/`**pattern:**`/`**ルール:**`）はTask1〜4で一貫
