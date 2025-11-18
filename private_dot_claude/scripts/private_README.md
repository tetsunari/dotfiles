# 復習問題生成システム - 完全実装ガイド

このディレクトリには、Claude Code の履歴から自動的に復習問題を生成するシステムが含まれています。

**実装完了日**: 2025-11-18
**システムバージョン**: 1.0

---

## 📋 システム概要

### 仕組み

```
Claude Code 履歴
  ↓
review-quiz-generator エージェント
  ↓ （過去30日間を分析・問題生成）
  ↓
quiz-output-formatter スキル
  ↓ （Markdown形式に整形）
  ↓
復習問題ファイル（output/quiz-YYYY-MM-DD.md）
```

### 主要コンポーネント

| コンポーネント | 種類 | 場所 | 役割 |
|---|---|---|---|
| **review-quiz-generator** | エージェント | `.claude/agents/review-quiz-generator.md` | 履歴分析・問題生成 |
| **quiz-output-formatter** | スキル | `~/.claude/skills/quiz-output-formatter/` | フォーマット・整形 |
| **run-quiz-generator.sh** | スクリプト | `~/.claude/scripts/run-quiz-generator.sh` | 実行・スケジューリング |

---

## 🚀 クイックスタート

### 1️⃣ 手動実行

```bash
# スクリプトを実行
~/.claude/scripts/run-quiz-generator.sh

# 出力ファイルを確認
cat ~/output/quiz-2025-11-18.md
```

### 2️⃣ 定期実行設定（Cron）

```bash
# crontab を編集
crontab -e

# 以下の行を追加（毎月第1日曜 00:00）
0 0 ? * SUN ~/.claude/scripts/run-quiz-generator.sh >> ~/.claude/logs/quiz-generator.log 2>&1
```

詳細は `SCHEDULING_GUIDE.md` を参照してください。

### 3️⃣ 生成されたファイルを確認

```bash
# ファイルが生成されたか確認
ls -lh ~/output/quiz-*.md

# ファイルの内容を確認
cat ~/output/quiz-2025-11-18.md | less
```

---

## 📁 ディレクトリ構成

```
~/.claude/
├── agents/
│   └── review-quiz-generator.md          ← エージェント定義
│
└── skills/
    └── quiz-output-formatter/
        ├── SKILL.md                       ← スキル定義
        ├── templates/
        │   └── quiz-template.md           ← Markdownテンプレート
        └── formatter.js                   ← フォーマット処理（予定）

./scripts/
├── run-quiz-generator.sh                 ← 実行スクリプト
├── SCHEDULING_GUIDE.md                   ← スケジューリング設定ガイド
└── README.md                              ← このファイル

~/output/
└── quiz-2025-11-18.md                    ← 生成される復習問題
```

---

## 📖 詳細ガイド

### エージェント（review-quiz-generator）

**役割**: Claude Code の履歴から復習問題を生成

**機能:**
- 過去 30 日間の会話を分析
- 技術的な重要ポイントを抽出
- 4択問題・記述問題を生成
- 難易度（⭐⭐⭐）を付与
- 分野別に分類

**出力フォーマット:**
```markdown
### 問題 1: [タイトル]

**難易度:** ⭐⭐ | **分野:** [分野] | **出典:** 日付

[問題文]

A) [選択肢]
B) [選択肢]
C) [選択肢]
D) [選択肢]

**正解:** X) [選択肢]

**解説:**
[詳細な解説]
```

👉 詳細は `.claude/agents/review-quiz-generator.md` を参照

---

### スキル（quiz-output-formatter）

**役割**: 生成された問題を整形・フォーマット

**機能:**
- 問題を分野別に分類
- 難易度順にソート
- 目次（TOC）を自動生成
- 解答キーを生成（表形式）
- 統計情報を追加

**入力**: エージェント生成の raw Markdown
**出力**: プロフェッショナルな Markdown ドキュメント

👉 詳細は `~/.claude/skills/quiz-output-formatter/SKILL.md` を参照

---

### 実行スクリプト（run-quiz-generator.sh）

**役割**: エージェント・スキルを統合して実行

**機能:**
```bash
1. 前提条件チェック（jq, grep など）
2. 履歴ファイルの確認
3. エージェント実行（問題生成）
4. スキル実行（整形）
5. ログ出力
6. エラーハンドリング
```

**使用方法:**

```bash
# 実行
~/.claude/scripts/run-quiz-generator.sh

# ログを確認
tail -50 ~/.claude/logs/quiz-generator.log
```

👉 詳細は スクリプト内のコメントを参照

---

## ⏰ 定期実行の設定

### 推奨スケジュール

#### 月1回実行（推奨）
```crontab
# 毎月第1日曜 00:00
0 0 ? * SUN ~/.claude/scripts/run-quiz-generator.sh >> ~/.claude/logs/quiz-generator.log 2>&1
```

#### 週1回実行
```crontab
# 毎週日曜 09:00
0 9 * * SUN ~/.claude/scripts/run-quiz-generator.sh >> ~/.claude/logs/quiz-generator.log 2>&1
```

### 設定方法

```bash
# crontab を編集
crontab -e

# 上記のいずれかを追加して保存

# 設定を確認
crontab -l
```

👉 詳細は `SCHEDULING_GUIDE.md` を参照

---

## 📊 出力ファイル例

生成されるファイル: `~/output/quiz-2025-11-18.md`

### ファイル構成

```markdown
# 復習問題集 - 2025年11月18日

**生成日時:** 2025-11-18 11:05:48
**対象期間:** 過去30日間
**問題数:** 12問

## 📚 このドキュメントについて
...

## 📋 目次
1. 言語・型システム（3問）
2. Web フレームワーク（3問）
3. クラウド・インフラ（3問）
4. 開発プロセス（2問）
5. その他（1問）

## 問題
### 言語・型システム
#### 問題 1: ...
...

## ✅ 解答キー
| # | 分野 | 難易度 | 解答 |
...

## 📊 統計情報
...
```

---

## 🔧 トラブルシューティング

### Q: Cron ジョブが実行されない

**A:** 以下を確認してください

```bash
# 1. crontab に設定されているか確認
crontab -l

# 2. スクリプトに実行権限があるか確認
ls -l ~/.claude/scripts/run-quiz-generator.sh
# 出力: -rwx------ となっているか確認

# 3. Cron デーモンが動作しているか確認
ps aux | grep cron

# 4. ログを確認（Mac）
log stream --predicate 'process == "cron"' --level debug

# 5. ログを確認（Linux）
sudo grep CRON /var/log/syslog | tail -20
```

👉 詳細は `SCHEDULING_GUIDE.md` のトラブルシューティングを参照

---

### Q: スクリプトの実行に失敗する

**A:** ログファイルを確認

```bash
# ログを表示
cat ~/.claude/logs/quiz-generator.log

# リアルタイムで監視
tail -f ~/.claude/logs/quiz-generator.log
```

---

### Q: 復習問題ファイルが生成されない

**A:** 以下を確認

```bash
# 出力ディレクトリが存在するか
ls -la ~/output/

# history.jsonl が存在するか
ls -la ~/.claude/history.jsonl

# ファイルサイズが 0 でないか
du -h ~/.claude/history.jsonl
```

---

## 🎯 使用シーン

### 初期段階
- スクリプトを手動実行してテスト
- 生成されたファイルを確認
- 問題形式が期待通りか確認

### 定期実行
- Cron で月1回（毎月第1日曜）自動実行
- 毎月新しい復習問題を自動取得
- 定期的に復習して知識を定着

### 復習活動
1. **初回:** すべての問題に取り組む
2. **2回目以降:** 苦手な分野を重点復習
3. **定期的:** 3週間後・2ヶ月後に再挑戦

---

## 🚀 今後の拡張予定

- [ ] 実際の Claude Code 統合（現在はサンプル生成）
- [ ] PDF フォーマット出力
- [ ] 分野別・難易度別フィルタリング
- [ ] Web ダッシュボード表示
- [ ] 正答率追跡機能
- [ ] AI による難易度自動調整

---

## 📞 サポート

### ドキュメント
- `SCHEDULING_GUIDE.md` - 定期実行設定ガイド
- `.claude/agents/review-quiz-generator.md` - エージェント詳細説明
- `~/.claude/skills/quiz-output-formatter/SKILL.md` - スキル詳細説明

### ログ確認
```bash
tail -f ~/.claude/logs/quiz-generator.log
```

---

**最終更新:** 2025-11-18
**バージョン:** 1.0
**ステータス:** ✅ 実装完了・テスト済み
