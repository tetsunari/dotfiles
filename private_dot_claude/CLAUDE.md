# Claude Code 設定ハーネス

- **言語**: Japanese
- **文字コード**: UTF-8

---

## rules/ 索引

| ファイル | 適用条件 | 内容 |
|---------|---------|------|
| `init.md` | 常時 | トークン削減：Claudeのトークン削除 の役割分担 |
| `trinity-development.md` | 常時 | 三位一体原則：ユーザー/Claude/Gemini の役割分担 |
| `ai-operations.md` | 常時 | AI運用8原則（確認ルール・自己改善ループ） |
| `rule.md` | 常時 | Skills vs Subagents 使い分けガイド |
| `agent-security.md` | 常時 | OWASP Agentic Top 10 + Least Agency 原則 |
| `core-principles.md` | 常時 | コア開発3原則（シンプル・根本原因・影響最小化） |
| `security.md` | 常時 | パッケージインストール時のセキュリティチェック |
| `ai-agent-principles.md` | 常時 | Production AIエージェント8原則 |
| `environment.md` | 常時 | コマンドエイリアス（bat/eza/fd/rg/zoxide） |
| `agents.md` | 常時 | エージェントオーケストレーション定義 |
| `coding-style.md` | `*.ts,tsx,js,jsx,...` | 不変性・ファイル構成・エラーハンドリング |
| `patterns.md` | `*.ts,tsx,js,jsx` | API応答形式・Custom Hooks・Repository パターン |
| `verification-loop.md` | 常時 | 検証完了基準（動作証明なき完了禁止・確認手順） |

---

## agents/ 索引

| エージェント | 用途 |
|------------|------|
| `code-reviewer` | コード品質・セキュリティレビュー |
| `security-reviewer` | セキュリティ脆弱性検出 |
| `spec-researcher` | 最新仕様・ベストプラクティス調査 |
| `web-researcher` | Gemini 経由 Web 検索 |
| `doc-updater` | ドキュメント・README 更新 |
| `refactor-cleaner` | デッドコード除去・整理 |
| `error-investigator` | エラー原因調査（試行錯誤を隔離） |

---

## 設計3原則（要約）

1. **シンプル第一** — 最小変更で要件を満たす
2. **根本原因対応** — 表面的な回避策を避ける
3. **影響最小化** — 変更範囲を要求箇所に限定

---

## セキュリティフレームワーク（要約）

- **OWASP Agentic Top 10**: ASI01（プロンプトインジェクション）・ASI02（ツール悪用）・ASI04（サードパーティリスク）・ASI09（人間の過信）
- **Least Agency**: Read=即実行 / Write・Bash・削除=事前確認必須 / 外部送信=機密チェック後に確認
