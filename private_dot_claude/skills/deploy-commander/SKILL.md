---
name: deploy-commander
description: デプロイ・リリース作業を行う時には必ずこのスキルを使う。ステージング・本番環境へのデプロイ、CI/CD設定、ビルドエラー解析、ロールバック実行を依頼された時に即座に起動。事前チェックリスト強制実行、複雑なコマンド抽象化、ビルドエラー自動解析、ロールバック手順管理。
context: fork
allowed-tools: Bash, Read
bash-restrictions: "aws ecs update-service, serverless deploy, cdk deploy 等の破壊操作は事前に差分確認（cdk diff 等）を経てからユーザー承認を得る。本番環境への直接操作は制限。cdk deploy 前は必ず cdk-infrastructure スキルで cdk diff を実行済みであること。"
---

# Deploy Commander: デプロイ・リリース自動化

## Overview

複雑なデプロイ手順とチェックリストを自動化し、人的ミスを軽減。ビルドエラーの自動解析と修正案提示、ロールバック手順の管理までサポート。

**Core principle:** 安全で再現可能なデプロイプロセスを確立し、リリースの信頼性を向上させる。

## When to Use

- ステージング/本番環境へのデプロイ
- リリース前の最終チェック
- ビルド・デプロイエラーの解析
- ロールバック実行
- CI/CDパイプラインの設定

## Supported Platforms

| プラットフォーム | デプロイコマンド | 詳細手順 |
|-----------------|-----------------|---------|
| AWS Lambda (Serverless Framework) | `serverless deploy` | `references/aws-lambda.md` |
| AWS ECS | `aws ecs update-service` | `references/aws-ecs.md` |
| Cloudflare Pages | `wrangler pages deploy` | `references/cloudflare-pages.md` |
| AWS CDK | `cdk deploy` | `references/cdk.md`（コード変更・synth検証は `cdk-infrastructure` スキル管轄） |

対象プラットフォームを判定したら、該当する `references/*.md` を読んでコマンド・ロールバック手順を実行する。

## Pre-Deploy Checklist

### Phase 1: コード品質チェック

```markdown
## 必須チェック

### テスト
- [ ] 全テストがパス: `npm test`
- [ ] E2Eテストがパス: `npm run test:e2e`
- [ ] カバレッジ基準達成: `npm run test:coverage`

### 静的解析
- [ ] Lintエラーなし: `npm run lint`
- [ ] 型エラーなし: `npm run type-check`
- [ ] セキュリティ脆弱性なし: `npm audit`

### ビルド
- [ ] ビルド成功: `npm run build`
- [ ] バンドルサイズ確認: `npm run analyze`
```

### Phase 2: 環境チェック

```markdown
## 環境変数確認

### 本番環境
- [ ] 必須環境変数がすべて設定済み
- [ ] シークレットがSecrets Managerに保存済み
- [ ] APIキーが本番用に更新済み

### データベース
- [ ] マイグレーション準備完了
- [ ] バックアップ取得済み
- [ ] ロールバックスクリプト準備

### 外部サービス
- [ ] サードパーティAPIの疎通確認
- [ ] CDN設定確認
- [ ] DNS設定確認
```

### Phase 3: ドキュメント確認

```markdown
## リリースドキュメント

- [ ] CHANGELOG更新済み
- [ ] バージョン番号更新済み
- [ ] リリースノート作成済み
- [ ] 影響範囲の文書化
```

## Deploy Commands

プラットフォーム別のデプロイコマンドは `references/` を参照:
- `references/aws-lambda.md`
- `references/aws-ecs.md`
- `references/cloudflare-pages.md`
- `references/cdk.md`

## Error Analysis

### ビルドエラーパターン

```typescript
const buildErrorPatterns = {
  // TypeScript型エラー
  typeError: {
    pattern: /TS\d+:/,
    solution: '型定義を確認し、型アサーションまたは型ガードを追加',
  },

  // モジュール解決エラー
  moduleNotFound: {
    pattern: /Cannot find module/,
    solution: '依存関係をインストール: npm install <package>',
  },

  // メモリ不足
  outOfMemory: {
    pattern: /JavaScript heap out of memory/,
    solution: 'NODE_OPTIONS="--max-old-space-size=4096" を設定',
  },

  // ESLintエラー
  lintError: {
    pattern: /ESLint|Parsing error/,
    solution: 'npm run lint -- --fix を実行',
  },
};
```

### デプロイエラーパターン

```typescript
const deployErrorPatterns = {
  // 認証エラー
  authError: {
    pattern: /unauthorized|authentication failed/i,
    solution: '認証情報を更新: <platform> login',
  },

  // リソース制限
  quotaExceeded: {
    pattern: /quota|limit exceeded/i,
    solution: 'プランのアップグレードまたはリソースクリーンアップ',
  },

  // タイムアウト
  timeout: {
    pattern: /timeout|timed out/i,
    solution: 'タイムアウト値を増加、またはリソースを最適化',
  },

  // ネットワークエラー
  networkError: {
    pattern: /ECONNREFUSED|network error/i,
    solution: 'ネットワーク接続を確認、VPN/プロキシ設定を確認',
  },
};
```

## Rollback Procedures

### 即時ロールバック

```markdown
## ロールバック判断基準

### 即時ロールバック（Critical）
- アプリケーションが起動しない
- 500エラーが多発
- データ破損の可能性

### 判断保留（Warning）
- パフォーマンス低下
- 軽微な機能不具合
- UI表示崩れ
```

### プラットフォーム別ロールバック

各 `references/*.md` の「ロールバック」セクションを参照。

### データベースロールバック

```bash
# Prisma
npx prisma migrate resolve --rolled-back <migration-name>

# Drizzle
npx drizzle-kit drop

# 手動SQL
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f rollback.sql
```

## Post-Deploy Verification

```markdown
## デプロイ後チェック

### ヘルスチェック
- [ ] エンドポイント疎通確認: `curl https://api.example.com/health`
- [ ] レスポンスタイム正常: < 200ms
- [ ] エラーレート正常: < 0.1%

### 機能確認
- [ ] 主要機能の動作確認
- [ ] 新機能の動作確認
- [ ] 既存機能のリグレッションなし

### モニタリング
- [ ] メトリクス正常
- [ ] アラート発生なし
- [ ] ログにエラーなし
```

## CI/CD Templates

### GitHub Actions

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install
        run: npm ci

      - name: Test
        run: npm test

      - name: Build
        run: npm run build

      - name: Deploy
        run: npm run deploy
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

## Key Principles

- **Checklist enforcement** - 必須チェックを自動化
- **Fail fast** - 問題は早期に検出
- **Rollback ready** - いつでもロールバック可能
- **Observable** - デプロイ状況を可視化
- **Reproducible** - 再現可能なデプロイ

## Integration

- **security-review** skill: デプロイ前セキュリティチェック
- **code-reviewer** skill: コード品質確認
- **cdk-infrastructure** skill: CDK 使用時のコード変更・`cdk synth` 検証・Logical ID ドリフト対応（デプロイ実行前に必ず経由する）
- **Gemini**: プラットフォーム固有の問題調査
