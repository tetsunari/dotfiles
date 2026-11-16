---
description: "サブエージェント委譲基準：委譲は大きな出力を使い捨てる時だけ。実装・レビュー・調査はスキルで行う"
alwaysApply: true
---
# サブエージェント委譲基準

> 基本は委譲せず、スキルとツールを使って自分で進める。サブエージェントは、元の会話に持ち込みたくない大きな出力を使い捨てるときだけ使う。
> 根拠: Anthropic「Building agents: When to fold subagents into your main agent loop」（2026-10-22）。引き継ぎで文脈が抜ける・作業が重複する・待ち時間が増えるため、必要性を示せるものだけ残す（2026-11-16 に 9 体 → 2 体へ整理）

## コンテキスト保護のための委譲

**ツール出力は一度親コンテキストに入ると、以降の全ターンで再送され続ける。**
出力量の見積もりが委譲判断の第一基準になる。

| 場面 | 委譲先 |
|------|--------|
| テスト・ビルドの実行と結果確認（失敗時のみ該当箇所を持ち帰る） | `test-runner` |
| Web 調査（agy / Gemini 経由） | `web-researcher` |
| 結果の大半を捨てる広範な探索（出力が数百行以上になる全文検索・ログ走査） | 標準の `Explore` |
| 独立した調査を並列で回す | 上の委譲先や標準の `Explore` を 1 メッセージで複数起動 |

親で直接 Bash を実行する場合は、出力を先に絞ってから返す：

- `head` / `tail` / `wc -l` / `--format` / `-q` で必要な行だけにする
- 長時間コマンドは `run_in_background` で回し、完了後に要約だけ読む
- ファイル全文の Read は、対象箇所が特定済みのときだけ。探索目的なら Grep

## 委譲しないもの（スキルで行う）

| 作業 | 使うもの |
|------|---------|
| 実装・修正 | 自分で行う（引き継ぎで文脈が抜けるため） |
| コードレビュー | `/ponytail-review` → `/code-review`、別モデルの視点は `codex-pr-review` |
| セキュリティ審査 | `security-review` スキル |
| バグ・エラー調査 | `diagnosing-bugs` スキル |
| ドキュメント作成・編集 | `document-writing` スキル |

## 実装時に読むスキル

次のスキルは `skillOverrides` で一覧から外してある。該当する実装・文書作成に入る前に、自分で `SKILL.md` を Read する。

| 対象 | 読むスキル |
|------|-----------|
| AWS Lambda 関数 | `~/.claude/skills/aws-lambda-typescript/SKILL.md` |
| DB スキーマ・マイグレーション | `~/.claude/skills/db-architect/SKILL.md` |
| OpenAPI スペック（YAML） | `~/.claude/skills/openapi-conventions/SKILL.md` |
| TypeScript / JS / React 全般 | `~/.claude/skills/coding/SKILL.md` |
| アーキテクチャ設計判断 | `~/.claude/skills/software-architecture/SKILL.md` |
| 技術記事（Zenn / Qiita）・API 仕様書・チュートリアル | `~/.claude/skills/technical-writer/SKILL.md` |

## コードレビュー

コードを変更したら、PR 作成前・コミット前に `/ponytail-review` → `/code-review` の順で回す（`ponytail-review-gate.sh` が順序を強制する）。

`/code-review` は正当性が中心なので（effort が高い段では内部でレビュー用サブエージェントを複数起動する）、次の観点は自分で足して見る：

- **並行性**: 競合状態・デッドロック・非冪等な処理・リトライ時の二重実行
- **プライバシー**: 個人情報・機密情報の不必要な保持・ログ出力・外部送信
- **ドメイン前提**: 業務ルール・不変条件・運用フロー上の暗黙の前提が崩れるケース

指摘の書き方：

- 冒頭に件数（例: `CRITICAL 1 / WARNING 2 / SUGGESTION 1 / 既存 1`）。無ければ「指摘なし」と書き、水増ししない
- 根拠は `ファイル:行番号`。名前からの推測は根拠にしない。呼び出し元・定義を読んで確かめたものだけ指摘する
- 変更前からある問題は `既存` として分ける
- SUGGESTION は重要度順に最大 3 件。スタイルだけの指摘（命名の好み・書式・言い回し）は出さない

## 委譲した成果物は親が確認する

要求範囲との一致・副作用の有無・`core-principles.md` への適合を、親セッション自身が確かめてから採用する。
