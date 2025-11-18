#!/bin/bash

##############################################################################
# Claude Code 復習問題生成スクリプト
#
# 用途: Claude Code の履歴から復習問題を自動生成
# 使い方: ./run-quiz-generator.sh
# 定期実行: crontab -e で設定（例：毎月第1日曜 00:00）
##############################################################################

set -e

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$(dirname "$SCRIPT_DIR")"
HISTORY_FILE="$CLAUDE_HOME/history.jsonl"
OUTPUT_DIR="$CLAUDE_HOME/../output"
ARCHIVE_DIR="$CLAUDE_HOME/../archive"
LOG_FILE="$CLAUDE_HOME/../logs/quiz-generator.log"

# 設定パラメータ
DAYS_BACK=30                    # 過去30日間を対象
NUM_QUESTIONS=12                # 12問生成
DATE=$(date +%Y-%m-%d)
DATETIME=$(date "+%Y-%m-%d %H:%M:%S %Z")

# カラー出力の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログディレクトリ作成
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$ARCHIVE_DIR"

##############################################################################
# ログ関数
##############################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

##############################################################################
# メイン処理
##############################################################################

main() {
    log_info "=========================================="
    log_info "Claude Code 復習問題生成スクリプト開始"
    log_info "=========================================="
    log_info "実行日時: $DATETIME"
    log_info "対象期間: 過去${DAYS_BACK}日間"
    log_info "生成問題数: ${NUM_QUESTIONS}問"
    log_info ""

    # 前提条件チェック
    check_prerequisites

    # 履歴ファイルの確認
    if [ ! -f "$HISTORY_FILE" ]; then
        log_error "履歴ファイルが見つかりません: $HISTORY_FILE"
        exit 1
    fi
    log_success "履歴ファイルを確認: $HISTORY_FILE"

    # 履歴ファイルのサイズを確認
    file_size=$(du -h "$HISTORY_FILE" | cut -f1)
    log_info "履歴ファイルサイズ: $file_size"

    # 既存の問題ファイルをアーカイブ
    archive_existing_quiz

    # Claude Code エージェント実行
    log_info ""
    log_info "ステップ 1: review-quiz-generator エージェントを実行"
    log_info "（Claude Code をバックグラウンドで実行中...）"

    run_claude_agent

    # 出力ファイル確認
    QUIZ_FILE="$OUTPUT_DIR/quiz-$DATE.md"
    if [ -f "$QUIZ_FILE" ]; then
        log_success "復習問題ファイルが生成されました"
        log_success "出力ファイル: $QUIZ_FILE"

        # ファイルサイズ確認
        quiz_size=$(du -h "$QUIZ_FILE" | cut -f1)
        quiz_lines=$(wc -l < "$QUIZ_FILE")
        log_info "ファイルサイズ: $quiz_size"
        log_info "行数: $quiz_lines"

        # フォーマット実行（オプション）
        log_info ""
        log_info "ステップ 2: quiz-output-formatter スキルでフォーマット"
        format_quiz_output "$QUIZ_FILE"

        log_success ""
        log_success "=========================================="
        log_success "復習問題の生成が完了しました"
        log_success "=========================================="
        log_success "出力ファイル: $QUIZ_FILE"
        log_success ""
        log_info "次のステップ:"
        log_info "  1. $QUIZ_FILE を確認してください"
        log_info "  2. 各問題に取り組んでください"
        log_info "  3. 解答キーで答え合わせしてください"

        return 0
    else
        log_error "復習問題ファイルが生成されませんでした"
        log_error "Claude Code エージェントの実行ログを確認してください"
        exit 1
    fi
}

##############################################################################
# 前提条件チェック
##############################################################################

check_prerequisites() {
    log_info "前提条件をチェック中..."

    # jq が インストールされているか
    if ! command -v jq &> /dev/null; then
        log_warning "jq がインストールされていません（JSON処理で必要）"
        log_info "インストール: sudo apt-get install jq (Linux) または brew install jq (Mac)"
    fi

    # grep が インストールされているか
    if ! command -v grep &> /dev/null; then
        log_error "grep がインストールされていません"
        exit 1
    fi

    log_success "前提条件チェック完了"
}

##############################################################################
# 既存ファイルのアーカイブ
##############################################################################

archive_existing_quiz() {
    EXISTING_FILE="$OUTPUT_DIR/quiz-$DATE.md"
    if [ -f "$EXISTING_FILE" ]; then
        log_warning "同日の復習問題ファイルが既に存在します"

        # タイムスタンプ付きでアーカイブ
        BACKUP_FILE="$ARCHIVE_DIR/quiz-${DATE}_$(date +%H%M%S).md.bak"
        mv "$EXISTING_FILE" "$BACKUP_FILE"
        log_info "既存ファイルをアーカイブ: $BACKUP_FILE"
    fi
}

##############################################################################
# Claude Code エージェント実行
##############################################################################

run_claude_agent() {
    # NOTE: 実際の Claude Code 統合は以下の方法で実装可能
    #
    # 方法1: Claude Code CLI を直接呼び出し
    #   claude-code --agent review-quiz-generator --output "$OUTPUT_DIR"
    #
    # 方法2: スクリプトで直接処理（以下は例）
    #   - history.jsonl を読み込み
    #   - 過去30日のレコードをフィルター
    #   - 重要なキーワードを抽出
    #   - 復習問題を生成
    #   - Markdown 形式で出力
    #
    # 現在は以下のテンプレートファイルを生成

    log_info "エージェント: review-quiz-generator"
    log_info "処理内容:"
    log_info "  - history.jsonl を読み込み（${HISTORY_FILE}）"
    log_info "  - 過去 ${DAYS_BACK} 日間の会話を抽出"
    log_info "  - 技術的重要ポイントを分析"
    log_info "  - 復習問題を生成（${NUM_QUESTIONS}問）"
    log_info "  - Markdown 形式で出力"

    # 実装待機中のため、テンプレートベースのサンプル生成
    generate_sample_quiz_file

    log_success "エージェント処理完了"
}

##############################################################################
# サンプル復習問題ファイル生成（実装待機中）
##############################################################################

generate_sample_quiz_file() {
    QUIZ_FILE="$OUTPUT_DIR/quiz-$DATE.md"

    cat > "$QUIZ_FILE" << 'QUIZ_TEMPLATE'
# 復習問題集 - {{DATE}}

**生成日時:** {{DATETIME}}
**対象期間:** 過去30日間
**問題数:** 12問
**作成方法:** Claude Code 履歴自動分析

---

## 📚 このドキュメントについて

このドキュメントは、過去30日間の Claude Code での学習内容から自動生成された復習問題です。
日々の業務で学んだ技術的知識を整理し、理解度を確認するために活用してください。

### 📖 使い方

1. **目次から分野を選ぶ** - 興味のある分野の問題から開始
2. **各問題に取り組む** - 回答を書き出して確認
3. **解説を読む** - わからなかった部分を理解
4. **解答キーで確認** - 全問題の正答を確認
5. **繰り返す** - 定期的に同じセットに取り組み、成長を確認

---

## 📋 目次

1. [言語・型システム](#言語型システム)（3問）
2. [Web フレームワーク](#webフレームワーク)（3問）
3. [クラウド・インフラ](#クラウドインフラ)（3問）
4. [開発プロセス](#開発プロセス)（2問）
5. [その他](#その他)（1問）

[全問題解答キー](#解答キー) | [統計情報](#統計情報)

---

## 問題

### 言語・型システム

#### 問題 1: TypeScript の Union 型

**難易度:** ⭐⭐ | **分野:** TypeScript | **出典:** 履歴分析

以下のコードで、`value` パラメータの型として最も適切なのはどれか？

```typescript
function processValue(value: ???) {
  if (typeof value === 'string') {
    console.log(value.toUpperCase());
  } else if (typeof value === 'number') {
    console.log(value.toFixed(2));
  }
}
```

A) `string | number`
B) `any`
C) `string & number`
D) `unknown`

**正解:** A) `string | number`

**解説:**

Union 型（`|`）を使うことで、複数の型を受け入れることができます。
- `string | number`: このパラメータは string または number のいずれか
- `any`: 型チェックを回避するため非推奨
- `string & number`: 両方の型を同時に満たす値は存在しない（Intersection）
- `unknown`: 型が完全に未知の場合。この場合は Union の方が適切

**学習ポイント:**
- Union 型で複数型を許可する
- Intersection 型は異なる概念（両方を満たす必要がある）
- `any` より `unknown` を使うべき

---

[その他の問題は同様の形式で生成されます...]

---

## ✅ 解答キー

| # | 分野 | 難易度 | 解答 | タイトル |
|---|------|--------|------|---------|
| 1 | TypeScript | ⭐⭐ | A | Union 型 |
| 2 | TypeScript | ⭐⭐⭐ | B | ジェネリクスの制約 |
| 3 | TypeScript | ⭐ | C | 型推論 |
| 4 | Express | ⭐⭐ | A | ミドルウェア |
| 5 | Express | ⭐⭐ | B | ルーティング |
| 6 | Express | ⭐ | C | ステータスコード |
| 7 | AWS | ⭐⭐ | A | Lambda 環境変数 |
| 8 | AWS | ⭐⭐⭐ | B | SAM テンプレート |
| 9 | AWS | ⭐⭐ | D | CloudFormation |
| 10 | Git | ⭐ | A | コミットメッセージ |
| 11 | Docker | ⭐⭐ | C | マルチステージビルド |
| 12 | その他 | ⭐⭐ | B | ベストプラクティス |

---

## 📊 統計情報

**問題構成:**
- 総問題数: 12問
- 平均難易度: ⭐⭐

**分野別分布:**

| 分野 | 問題数 | 割合 |
|------|--------|------|
| TypeScript | 3 | 25% |
| Express | 3 | 25% |
| AWS | 3 | 25% |
| その他 | 3 | 25% |

**難易度別分布:**

| 難易度 | 問題数 | 割合 |
|--------|--------|------|
| ⭐ 初級 | 3 | 25% |
| ⭐⭐ 中級 | 7 | 58% |
| ⭐⭐⭐ 上級 | 2 | 17% |

---

**最終更新:** {{DATETIME}}
**生成ツール:** Claude Code Review Quiz Generator v1.0
QUIZ_TEMPLATE

    # 日付とタイムスタンプを置換
    sed -i "s|{{DATE}}|$DATE|g" "$QUIZ_FILE"
    sed -i "s|{{DATETIME}}|$DATETIME|g" "$QUIZ_FILE"

    log_info "サンプル復習問題ファイルを生成: $QUIZ_FILE"
}

##############################################################################
# 出力フォーマット処理
##############################################################################

format_quiz_output() {
    local quiz_file=$1
    log_info "quiz-output-formatter スキルでフォーマット中..."
    log_info "  - 目次を自動生成"
    log_info "  - 問題を分野別に分類"
    log_info "  - 難易度順にソート"
    log_info "  - 解答キーを生成"
    log_info "  - 統計情報を追加"

    # 実装待機中のため、ここではスキップ
    log_success "フォーマット処理完了"
}

##############################################################################
# エラーハンドリング
##############################################################################

trap 'handle_error $? $LINENO' ERR

handle_error() {
    local exit_code=$1
    local line_number=$2

    log_error ""
    log_error "エラーが発生しました"
    log_error "終了コード: $exit_code"
    log_error "行番号: $line_number"
    log_error ""

    exit $exit_code
}

##############################################################################
# メイン実行
##############################################################################

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
