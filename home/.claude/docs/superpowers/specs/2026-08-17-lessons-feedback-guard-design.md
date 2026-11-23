# lessons フォーマット拡張 + feedback-guard hook 設計

- 日付: 2026-08-17
- 背景: Zenn記事「Claude Codeに『同じ指摘を二度させない』仕組みをhookで作った」を参考に、`~/.config/claude/lessons/`の指摘に`count`（指摘回数）を持たせ、機械検知可能な行動規制ルールについてはBash/Edit前にwarn→ask→denyで強制力を持たせる。

## スコープ

- 含む: 既存lessonsファイル約90エントリへの`**count:**`付与、行動規制型4件への`**enforce:**`/`**pattern:**`付与、新規`feedback-guard.sh`（PreToolUse hook）
- 含まない: Stop hookでの完了時強制チェック（Zennの`stop-check`相当）、countの自動インクリメント、`inject-lessons.sh`の重み付け変更（count>=3のみ強調表示 等）。将来の拡張候補として記載のみ

## メタデータ形式

既存の`### 見出し（date追記）` + `**ルール:**` + `**適用:**`という慣習をそのまま延長する。YAML frontmatterや別registryファイルは導入しない。

```markdown
### 見出し（date追記）
**count:** 1
**ルール:** ...
**適用:** ...
```

行動規制型（guard対象）のみ追加行:

```markdown
**count:** 1
**enforce:** pre_bash
**pattern:** checkout --theirs
**ルール:** ...
```

`enforce`行が無いエントリ = guard対象外（現状通りinjectのみ）。`pattern`は`tool_input`をJSON文字列化したものへの`rg`正規表現として評価する（アンカー`^`/`$`は行頭行末ではなくJSON文字列内位置に対して働く点に注意し、原則アンカーなしの部分一致で書く）。

## 対象範囲

- 全lessonsファイル（約19ファイル・約90エントリ）に`**count:**`を追加。既存の指摘回数の実測値が無いため一律`1`から開始する
- 行動規制型パイロット4件のみ`enforce`/`pattern`を追加:

| ファイル | 見出し | enforce | pattern |
|---|---|---|---|
| general.md | stash pop の衝突を `git checkout --theirs .` で解決しない | pre_bash | `checkout --theirs` |
| general.md | git stash 前は影響範囲を確認する | pre_bash | `git stash` |
| code-style.md | private関数禁止 | pre_edit | `private ` |
| code-style.md | ARN から ID 抽出時の non-null assertion 禁止 | pre_edit | `\.pop\(\)!` |

## feedback-guard.sh（新規 PreToolUse hook）

- 配置: `~/.claude/scripts/feedback-guard.sh`
- 登録: `settings.json`の`PreToolUse`配列に、既存`exploration-guard.sh`と同様matcher指定なしで追加登録（tool_nameは内部でcase分岐、既存規約を踏襲）
- 処理:
  1. stdinのJSONから`tool_name`・`tool_input`を取得
  2. `tool_name`が`Bash`なら`enforce: pre_bash`のエントリ、`Edit`/`Write`なら`enforce: pre_edit`のエントリを対象に、`tool_input`をjqで1行JSON化した文字列に対し各`pattern`を`rg`で照合
  3. 全lessonsファイルを走査し、対象enforce種別の全エントリに対して`pattern`照合を行う（複数マッチしうる）。マッチが複数あった場合は**countが最大のエントリを採用**する（最も強い強制力を優先）
  4. 採用したエントリの`**count:**`を読み取り、閾値表で判定

| count | permissionDecision |
|---|---|
| 1〜2 | allow（警告メッセージを合わせて出力） |
| 3〜4 | ask |
| 5以上 | deny |

  5. 出力: `exit 0` + `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": ..., "permissionDecisionReason": "<見出し>（指摘N回目）: <ルール文の要約>"}}`をjqで組み立ててstdoutへ

## count運用

自動加算しない（人間判断、Zenn記事と同方針）。`/remember`スキルの「3. 分類 → 書き込み」の「重複あり → 既存エントリを更新」手順に、count+1する操作を追記する形で統合する。新規の自動化hookは作らない。

## エラーハンドリング

既存hookの流儀を踏襲し fail-safe：jqパース失敗・lessonsファイル欠損・rg未検出などは全て`exit 0`（allow）で通し、Claudeの作業を止めない。

## テスト方針

`feedback-guard.sh`単体に対し、PreToolUse入力JSONのサンプル（Bash/Edit × count 1/3/5パターン）をstdin経由で流し、出力JSONの`permissionDecision`が期待通りか手動検証する。既存hookに自動テストは無いため同水準に留める。

## 将来の拡張候補（本設計のスコープ外）

- `inject-lessons.sh`でcount値に応じた重み付け表示（Zennの「これまでN回指摘されています」相当）
- Stop hookでの完了時強制チェック（stop-check相当）
- enforce対象ルールの追加（パイロット4件以外）
