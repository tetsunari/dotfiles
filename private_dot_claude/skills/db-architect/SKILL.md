---
name: db-architect
description: DB設計・マイグレーション管理を一貫サポート。スキーマ変更提案、マイグレーションファイル生成、ER図更新、Prisma/Drizzle/TypeORM対応。
context: fork
---

# DB Architect: データベース設計・マイグレーション管理

## Overview

データベース設計からマイグレーション管理まで一貫してサポート。スキーマ変更提案、マイグレーションファイル生成、ドキュメント更新を対話形式で実行。

**Core principle:** データの整合性・パフォーマンス・保守性を考慮した堅牢なDB設計を実現する。

## When to Use

- 新規テーブル・カラム追加
- スキーマ変更・リファクタリング
- マイグレーション戦略の検討
- インデックス最適化
- ER図・ドキュメント更新
- ORM設定の変更

## Supported ORMs

| ORM | 設定ファイル | マイグレーション |
|-----|-------------|-----------------|
| Prisma | `prisma/schema.prisma` | `npx prisma migrate` |
| Drizzle | `drizzle.config.ts` | `npx drizzle-kit` |
| TypeORM | `data-source.ts` | `npx typeorm migration:` |
| Knex | `knexfile.ts` | `npx knex migrate:` |
| Raw SQL | `migrations/*.sql` | 手動実行 |

## Design Process

### Phase 1: 要件分析

**質問テンプレート:**

```markdown
## データ要件の確認

1. **エンティティ**
   - 何を管理したいですか？
   - 既存テーブルとの関係は？

2. **属性**
   - 必要なフィールドは？
   - 必須/任意の区別は？
   - データ型の制約は？

3. **関係**
   - 1:1 / 1:N / N:M ？
   - 参照整合性の要件は？
   - カスケード削除は必要？

4. **制約**
   - ユニーク制約は？
   - チェック制約は？
   - デフォルト値は？

5. **パフォーマンス**
   - 想定データ量は？
   - 主要なクエリパターンは？
   - インデックス要件は？
```

### Phase 2: スキーマ設計

**設計原則:**

```markdown
## 正規化のガイドライン

### 第1正規形 (1NF)
- 各カラムは原子値（分割不可能な値）
- 繰り返しグループを排除

### 第2正規形 (2NF)
- 1NFを満たす
- 部分関数従属を排除

### 第3正規形 (3NF)
- 2NFを満たす
- 推移関数従属を排除

### 非正規化の判断
- パフォーマンス要件に基づく
- 読み取り頻度 >> 書き込み頻度 の場合
- 計測に基づいて判断
```

**命名規則:**

```typescript
const namingConventions = {
  // テーブル名: snake_case, 複数形
  tables: 'users, orders, order_items',

  // カラム名: snake_case
  columns: 'user_id, created_at, is_active',

  // プライマリキー: id または table_id
  primaryKeys: 'id, user_id',

  // 外部キー: referenced_table_id
  foreignKeys: 'user_id, order_id',

  // インデックス: idx_table_columns
  indexes: 'idx_users_email, idx_orders_user_id_status',

  // ユニーク制約: uniq_table_columns
  uniqueConstraints: 'uniq_users_email',
};
```

### Phase 3: スキーマ定義

**Prisma例:**

```prisma
// prisma/schema.prisma

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  posts     Post[]
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  @@map("users")
  @@index([email])
}

model Post {
  id        String   @id @default(cuid())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id], onDelete: Cascade)
  authorId  String   @map("author_id")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  @@map("posts")
  @@index([authorId])
  @@index([published, createdAt])
}
```

**Drizzle例:**

```typescript
// src/db/schema.ts
import { pgTable, text, boolean, timestamp, index } from 'drizzle-orm/pg-core';
import { createId } from '@paralleldrive/cuid2';

export const users = pgTable('users', {
  id: text('id').primaryKey().$defaultFn(() => createId()),
  email: text('email').notNull().unique(),
  name: text('name'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => ({
  emailIdx: index('idx_users_email').on(table.email),
}));

export const posts = pgTable('posts', {
  id: text('id').primaryKey().$defaultFn(() => createId()),
  title: text('title').notNull(),
  content: text('content'),
  published: boolean('published').default(false).notNull(),
  authorId: text('author_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => ({
  authorIdx: index('idx_posts_author_id').on(table.authorId),
  publishedCreatedIdx: index('idx_posts_published_created').on(table.published, table.createdAt),
}));
```

### Phase 4: マイグレーション生成

**安全なマイグレーション戦略:**

```markdown
## マイグレーションチェックリスト

### 実行前
- [ ] バックアップ取得済み
- [ ] ロールバック手順確認
- [ ] 本番データ量での所要時間見積もり
- [ ] メンテナンスウィンドウ確保

### カラム追加
- [ ] NOT NULL の場合はデフォルト値設定
- [ ] 既存データへの影響確認

### カラム削除
- [ ] アプリケーションコードから参照削除済み
- [ ] 段階的削除（deprecate → remove）

### カラム変更
- [ ] データ型変更の互換性確認
- [ ] データ損失リスクの評価

### テーブル削除
- [ ] 外部キー参照の確認
- [ ] バックアップからの復元手順
```

**Prismaマイグレーション:**

```bash
# 開発環境
npx prisma migrate dev --name add_posts_table

# 本番環境
npx prisma migrate deploy

# マイグレーション状態確認
npx prisma migrate status
```

**Drizzleマイグレーション:**

```bash
# マイグレーション生成
npx drizzle-kit generate

# マイグレーション実行
npx drizzle-kit migrate

# スキーマ確認
npx drizzle-kit studio
```

### Phase 5: ドキュメント更新

**ER図生成:**

```markdown
## ER図更新

### Mermaid形式

\`\`\`mermaid
erDiagram
    USERS ||--o{ POSTS : writes
    USERS {
        string id PK
        string email UK
        string name
        datetime created_at
        datetime updated_at
    }
    POSTS {
        string id PK
        string title
        string content
        boolean published
        string author_id FK
        datetime created_at
        datetime updated_at
    }
\`\`\`

### 出力先
- docs/database/er-diagram.md
- README.md（簡易版）
```

**データ辞書:**

```markdown
## データ辞書

### users テーブル

| カラム | 型 | NULL | 説明 |
|--------|-----|------|------|
| id | TEXT | NO | プライマリキー (CUID) |
| email | TEXT | NO | メールアドレス (ユニーク) |
| name | TEXT | YES | 表示名 |
| created_at | TIMESTAMP | NO | 作成日時 |
| updated_at | TIMESTAMP | NO | 更新日時 |

### インデックス

| 名前 | カラム | 用途 |
|------|--------|------|
| idx_users_email | email | ログイン時の検索 |
```

## Design Patterns

### Soft Delete

```prisma
model Post {
  id        String    @id @default(cuid())
  // ... other fields
  deletedAt DateTime? @map("deleted_at")

  @@index([deletedAt])
}
```

### Audit Trail

```prisma
model AuditLog {
  id         String   @id @default(cuid())
  tableName  String   @map("table_name")
  recordId   String   @map("record_id")
  action     String   // CREATE, UPDATE, DELETE
  oldValues  Json?    @map("old_values")
  newValues  Json?    @map("new_values")
  userId     String   @map("user_id")
  createdAt  DateTime @default(now()) @map("created_at")

  @@map("audit_logs")
  @@index([tableName, recordId])
  @@index([userId])
}
```

### Multi-tenancy

```prisma
model Tenant {
  id    String @id @default(cuid())
  name  String
  users User[]
}

model User {
  id       String @id @default(cuid())
  tenantId String @map("tenant_id")
  tenant   Tenant @relation(fields: [tenantId], references: [id])
  // ... other fields

  @@index([tenantId])
}
```

## Key Principles

- **Data integrity first** - 整合性制約を適切に設定
- **Measure before optimize** - インデックスは計測に基づいて
- **Safe migrations** - ロールバック可能な変更
- **Document changes** - ER図・データ辞書を同期更新
- **Incremental changes** - 大きな変更は分割して実行

## Integration

- **ddd** skill: ドメインモデルとの整合性
- **security-review** skill: データ保護・アクセス制御
- **Gemini**: 最新のDB設計パターン調査
