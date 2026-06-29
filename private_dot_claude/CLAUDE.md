# Claude Code 設定ハーネス

- **言語**: Japanese
- **文字コード**: UTF-8

---

## rules/ 索引

| ファイル | 適用条件 | 内容 |
|---------|---------|------|
| `init.md` | 常時 | 出力トークン圧縮ルール |
| `trinity-development.md` | 常時 | 三位一体原則：ユーザー/Claude/Gemini の役割分担 |
| `ai-operations.md` | 常時 | AI運用10原則（確認ルール・自己改善ループ） |
| `agent-security.md` | 常時 | OWASP Agentic Top 10 + Least Agency 原則 |
| `core-principles.md` | 常時 | コア開発3原則（シンプル・根本原因・影響最小化） |
| `security.md` | 常時 | パッケージインストール時のセキュリティチェック |
| `ai-agent-principles.md` | 常時 | Production AIエージェント8原則 |
| `environment.md` | 常時 | コマンドエイリアス（bat/eza/fd/rg/zoxide） |
| `agents.md` | 常時 | エージェントオーケストレーション定義 |
| `coding-style.md` | `*.ts,tsx,js,jsx,...` | 不変性・ファイル構成・エラーハンドリング |
| `patterns.md` | `*.ts,tsx,js,jsx` | API応答形式・Custom Hooks・Repository パターン |
| `verification-loop.md` | 常時 | 検証完了基準（動作証明なき完了禁止・確認手順） |
| `delegation.md` | 常時 | サブエージェント委譲基準・委譲マトリクス |
| `document-writing.md` | ドキュメント作成時 | 見やすい手順書ノウハウ（簡潔・3階層・項番・コピペ完結・危険箇所強調） |

---

## agents/ 索引
| エージェント | モデル | 用途 |
|------------|--------|------|
| `code-explore` | sonnet | 広範なコード調査・シンボル検索・依存関係追跡 |
| `implementer` | sonnet | 仕様明確な実装（設計不要・箇所特定済み） |
| `heavy-implementer` | opus | 複雑な実装・大規模変更・設計判断あり |
| `test-runner` | haiku | テスト実行・結果確認 |
| `code-reviewer` | sonnet | コード品質・セキュリティレビュー |
| `security-reviewer` | opus | セキュリティ脆弱性検出 |
| `spec-researcher` | sonnet | 最新仕様・ベストプラクティス調査 |
| `web-researcher` | sonnet | Gemini 経由 Web 検索 |
| `doc-updater` | opus | ドキュメント・README 更新 |
| `refactor-cleaner` | opus | デッドコード除去・整理 |
| `error-investigator` | opus | エラー原因調査（試行錯誤を隔離） |
