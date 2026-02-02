---
name: code-reviewer
description: プロジェクト固有のコーディング規約に基づく対話的コードレビュー。命名規則、禁止パターン、ディレクトリごとの条件分岐、修正案提示を実行。
context: fork
---

# Code Reviewer: 対話的コードレビュー

## Overview

プロジェクト固有の規約に基づいて、対話形式でコードレビューを実施。問題の指摘だけでなく、修正案の提示と適用までサポート。

**Core principle:** コードの品質・保守性・セキュリティを向上させ、チーム全体の成長を促進する。

## When to Use

- 新機能・変更のコードレビュー
- PRマージ前の品質チェック
- リファクタリング前の現状分析
- コーディング規約の遵守確認
- セキュリティ・パフォーマンス監査

## Review Dimensions

### 1. 命名規則

```typescript
// プロジェクト規約例
const namingRules = {
  // 変数・関数: camelCase
  variables: /^[a-z][a-zA-Z0-9]*$/,

  // 定数: UPPER_SNAKE_CASE
  constants: /^[A-Z][A-Z0-9_]*$/,

  // クラス・型: PascalCase
  types: /^[A-Z][a-zA-Z0-9]*$/,

  // ファイル: kebab-case.ts
  files: /^[a-z][a-z0-9-]*\.ts$/,

  // React コンポーネント: PascalCase.tsx
  components: /^[A-Z][a-zA-Z0-9]*\.tsx$/,
};
```

**チェックポイント:**

- [ ] 変数名が意図を表現している
- [ ] 略語を避け、明確な名前を使用
- [ ] 一貫した命名パターン
- [ ] ドメイン用語との整合性

### 2. 禁止パターン

```typescript
// 禁止パターン一覧
const forbiddenPatterns = {
  // any型の使用禁止
  anyType: /: any\b/,

  // console.log の残存禁止
  consoleLog: /console\.log\(/,

  // 直接的なDOM操作禁止（React）
  directDOM: /document\.(getElementById|querySelector)/,

  // 同期的なファイル操作禁止
  syncFS: /fs\.(readFileSync|writeFileSync)/,

  // ハードコードされた秘密情報
  hardcodedSecrets: /(api[_-]?key|password|secret)\s*[:=]\s*['"][^'"]+['"]/i,
};
```

**重大度分類:**

| レベル | 説明 | 対応 |
|--------|------|------|
| Critical | セキュリティ・データ破損リスク | 即時修正必須 |
| Error | 機能不全・バグの原因 | マージ前修正 |
| Warning | 品質・保守性の問題 | 改善推奨 |
| Info | スタイル・最適化提案 | 任意対応 |

### 3. ディレクトリ別ルール

```typescript
// ディレクトリごとの条件分岐
const directoryRules = {
  'src/domain/': {
    // DDD適用
    patterns: ['Entity', 'ValueObject', 'Aggregate', 'Repository'],
    rules: [
      'ドメインロジックは純粋関数で実装',
      '外部依存は Repository 経由',
      'UI/インフラ層への依存禁止',
    ],
  },

  'src/infrastructure/': {
    // インフラ層
    rules: [
      'ドメイン層のインターフェースを実装',
      '外部サービス・DBへのアクセスを担当',
    ],
  },

  'src/presentation/': {
    // プレゼンテーション層
    rules: [
      'ビジネスロジックを含まない',
      'ドメイン層を直接参照可',
      'インフラ層への直接依存禁止',
    ],
  },

  'src/components/': {
    // Reactコンポーネント
    rules: [
      'Propsの型定義必須',
      '1ファイル1コンポーネント',
      'hooks は use* プレフィックス',
    ],
  },

  'src/hooks/': {
    // カスタムフック
    rules: [
      'use* プレフィックス必須',
      '単一責任の原則',
      'テスト必須',
    ],
  },
};
```

### 4. 品質チェック

**コード品質:**

```markdown
## 関数の複雑度
- [ ] 1関数50行以内
- [ ] ネスト4レベル以内
- [ ] パラメータ5個以内
- [ ] 単一責任の原則

## エラーハンドリング
- [ ] try-catch の適切な使用
- [ ] エラーメッセージが明確
- [ ] リカバリー可能なエラーの処理
- [ ] ログ出力の適切さ

## テスト
- [ ] ユニットテストの存在
- [ ] エッジケースのカバー
- [ ] モックの適切な使用
```

**パフォーマンス:**

```markdown
## 非効率パターン
- [ ] N+1クエリ問題
- [ ] 不要な再レンダリング
- [ ] メモ化の適切な使用
- [ ] 大量データの効率的処理
```

**セキュリティ:**

```markdown
## OWASP Top 10
- [ ] インジェクション対策
- [ ] 認証・認可の適切さ
- [ ] 機密データの保護
- [ ] XSS対策
```

## Review Process

### Step 1: コンテキスト理解

```markdown
1. 変更の目的を確認
   - PRタイトル・説明を読む
   - 関連Issue/チケットを確認

2. 影響範囲の把握
   - 変更ファイル一覧
   - 依存関係の確認

3. プロジェクト規約の確認
   - CLAUDE.md
   - .eslintrc
   - tsconfig.json
```

### Step 2: レビュー実行

```markdown
## レビュー順序

1. **アーキテクチャレベル**
   - 責任分離は適切か
   - 依存関係の方向は正しいか

2. **モジュールレベル**
   - インターフェースは明確か
   - 凝集度は高いか

3. **関数レベル**
   - 単一責任を満たしているか
   - 副作用は適切に管理されているか

4. **行レベル**
   - 命名は明確か
   - ロジックは正しいか
```

### Step 3: フィードバック提示

```markdown
## フィードバック形式

### [Critical] セキュリティ: SQLインジェクションの脆弱性

**場所:** `src/repository/user.ts:45`

**問題:**
\`\`\`typescript
// 危険: 直接文字列結合
const query = `SELECT * FROM users WHERE id = ${userId}`;
\`\`\`

**修正案:**
\`\`\`typescript
// 安全: プレースホルダー使用
const query = 'SELECT * FROM users WHERE id = $1';
const result = await db.query(query, [userId]);
\`\`\`

**理由:** ユーザー入力を直接SQLに埋め込むと、攻撃者が任意のSQLを実行できる。

---

### [Warning] 命名: 意図が不明確

**場所:** `src/utils/helper.ts:12`

**問題:**
\`\`\`typescript
const d = new Date();
\`\`\`

**修正案:**
\`\`\`typescript
const currentDate = new Date();
\`\`\`
```

### Step 4: 修正適用

```markdown
## 修正適用オプション

1. **自動適用**
   - ユーザー確認後、Editツールで修正

2. **差分提示**
   - 修正前後の差分を表示
   - ユーザーが手動で適用

3. **コミット作成**
   - 修正をコミットとして作成
   - レビュー修正として記録
```

## Review Templates

### PR レビューコメント

```markdown
## レビューサマリー

**全体評価:** ⭐⭐⭐⭐☆ (4/5)

### 良い点
- 単一責任の原則が守られている
- テストカバレッジが十分

### 改善点
| 重大度 | 件数 | 対応 |
|--------|------|------|
| Critical | 0 | - |
| Error | 2 | 修正必須 |
| Warning | 5 | 推奨 |
| Info | 3 | 任意 |

### 詳細

[以下、個別のフィードバック]
```

## Key Principles

- **Constructive feedback** - 批判ではなく改善提案
- **Context-aware** - プロジェクト規約を尊重
- **Prioritized** - 重大度で優先順位付け
- **Actionable** - 具体的な修正案を提示
- **Educational** - なぜ問題かを説明

## Integration

- **security-review** skill: セキュリティ観点の深掘り
- **kaizen** skill: 継続的改善の視点
- **tidying** skill: リファクタリング提案
- **code-reviewer** agent: 自動レビュー実行
