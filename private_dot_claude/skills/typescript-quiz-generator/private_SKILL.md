---
name: typescript-quiz-generator
description: |
  TypeScript・AWS CDK/SDK の問題を汎用的に生成する最新ベストプラクティス対応スキル。

  複数の問題タイプ（4択・記述・レビュー・デバッグ）に対応し、
  Effective TypeScript、TypeScript 5.x、AWS CDK v2 の最新ベストプラクティスを
  問題に組み込みます。

  機能:
  - 複数問題タイプの自動生成（4択/記述/レビュー/デバッグ）
  - 技術領域のカスタマイズ（TypeScript/非同期処理/AWS など）
  - 難易度調整（初級～上級）
  - ベストプラクティスの自動組み込み
  - 参考資源の自動追加
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep
---

# TypeScript 問題ジェネレータ（汎用・最新ベストプラクティス対応）

TypeScript・AWS CDK/SDK の問題を効率的に生成するスキルです。
複数の問題タイプ・難易度・分野に対応し、常に最新のベストプラクティスを反映します。

---

## 📚 対応する技術領域

### Core TypeScript
- **型定義**: Union, Intersection, Generic, Utility Types
- **高度な型操作**: 条件付き型、型推論、Mapped Types
- **型ガード・型述語**: 型を絞り込む手法
- **Decorator パターン**: TypeScript 5.x の改善に対応

### 非同期処理
- **Promise の基本**: コンストラクタ、状態、チェーン
- **async/await**: 使い方、エラーハンドリング
- **フロー制御**: Promise.all/race/allSettled/any
- **エラーハンドリング**: try/catch、リトライパターン、タイムアウト

### AWS CDK/SDK
- **CDK**: Stack、Construct、Props インターフェース
- **Lambda**: 関数定義、環境変数、非同期処理
- **DynamoDB**: テーブル定義、SDK 操作、型安全性
- **S3**: バケット操作、非同期処理
- **複合シナリオ**: 複数 AWS サービスの組み合わせ

### 高度なパターン
- **型安全なビルダーパターン**: Generic を活用した流暢な API 設計
- **リポジトリパターン**: データアクセス層の型安全実装
- **Decorator パターン**: メタデータ付きプログラミング

---

## 🎯 4 つの問題タイプ

### 1️⃣ 4択問題（型定義・構文）

**用途**: 知識確認、理解度チェック

**例:**
```markdown
## 問題 1: Union 型の使い方

以下のコードで、`value` パラメータの型として最も適切なのはどれか？

\`\`\`typescript
function processValue(value: ???) {
  if (typeof value === 'string') {
    console.log(value.toUpperCase());
  } else if (typeof value === 'number') {
    console.log(value.toFixed(2));
  }
}
\`\`\`

A) `string | number`
B) `any`
C) `string & number`
D) `unknown`

**正解:** A) `string | number`

**解説:**
Union 型（`|`）を使うことで、複数の型を受け入れられます。

- **A) `string | number`** ← 正解。パラメータが string または number であることを明示
- **B) `any`** - 型チェックを回避するため非推奨。Effective TypeScript Item 38 参照
- **C) `string & number`** - Intersection 型。両方の型を満たす値は存在しない
- **D) `unknown`** - より安全だが、この場合は Union の方が適切

**学習ポイント:**
- Union 型で複数型を許可する
- Intersection 型は異なる概念（両方を満たす必要がある）
- `any` より `unknown` を使うべき（ただし Union が適切な場合もある）

**参考:**
- Effective TypeScript Item 8（型空間と値空間）
- Effective TypeScript Item 38（any 型を避ける）
- TypeScript Handbook: Union Types
```

**生成ロジック:**
1. 問題文（コード例付き）を生成
2. 4 つの選択肢を生成（正解 1 + 誤りやすい選択肢 3）
3. 正解を明示
4. 各選択肢に解説を添付
5. ベストプラクティスを組み込む
6. 参考資源を列挙

---

### 2️⃣ 記述問題（コード実装）

**用途**: 実装能力確認、深い理解

**例:**
```markdown
## 問題 2: async 関数でエラーハンドリング

以下の関数を async/await を使って実装してください。

### 仕様
- `fetchUser()` と `fetchPosts()` を順に実行（逐次処理）
- 両方が成功したら `{ user, posts }` を返す
- どちらかが失敗したら、エラーメッセージをコンソールに出力して null を返す
- 最後にクリーンアップ処理を実行

### 実装例（複数パターン）

**パターン 1: 標準的な try/catch（推奨）**
\`\`\`typescript
async function loadUserData(
  userId: number
): Promise<{ user: User; posts: Post[] } | null> {
  try {
    const user = await fetchUser(userId);
    const posts = await fetchPosts(userId);
    return { user, posts };
  } catch (error) {
    console.error(`Failed to load user data: ${error}`);
    return null;
  } finally {
    console.log('Cleanup completed');
  }
}
\`\`\`

**パターン 2: エラー型をチェック**
\`\`\`typescript
async function loadUserData(
  userId: number
): Promise<{ user: User; posts: Post[] } | null> {
  try {
    const user = await fetchUser(userId);
    const posts = await fetchPosts(userId);
    return { user, posts };
  } catch (error) {
    if (error instanceof NetworkError) {
      console.error('Network error:', error.message);
    } else if (error instanceof ValidationError) {
      console.error('Validation error:', error.message);
    } else {
      console.error('Unknown error:', error);
    }
    return null;
  } finally {
    console.log('Cleanup completed');
  }
}
\`\`\`

### 解説

**推奨ポイント:**
- try/catch でエラーハンドリングを一元化（.catch() チェーンより読みやすい）
- 戻り値を Union 型で明示（`Promise<T | null>`）
- finally ブロックでリソースクリーンアップを確実に実行
- エラー型をチェックして、適切なログを出力

**避けるべきパターン:**
- 各 await に .catch() を付ける（読みにくく、エラーが見落とされやすい）
- エラーを隠蔽する（常にコンソール出力 or 呼び元に委譲）
- try/catch なしで非同期処理を記述（未処理の Promise rejection）

**参考:**
- Effective TypeScript Item 31（null と undefined を型周辺に集約）
- TypeScript Handbook: Async Await
- AWS SDK Error Handling Guide
```

**生成ロジック:**
1. 要件を明示
2. 複数の実装パターンを提示（ベストプラクティス重視）
3. 各パターンの長所・短所を解説
4. 避けるべきパターンを明示
5. 参考資源を列挙

---

### 3️⃣ コードレビュー問題

**用途**: ベストプラクティス理解、批判的思考力

**例:**
```markdown
## 問題 3: コードレビュー - エラーハンドリング

以下のコードをレビューしてください。問題点と改善案を提示してください。

### 元のコード
\`\`\`typescript
async function saveUser(userData: any) {
  const response = await fetch('/api/users', {
    method: 'POST',
    body: JSON.stringify(userData),
  });
  const result = await response.json();
  return result;
}
\`\`\`

### 問題点（複数あります）

1. **型安全性がない** ⚠️
   - パラメータが `any` → 不正な値が渡される可能性
   - 戻り値の型が不明確

2. **エラーハンドリングがない** ⚠️
   - ネットワークエラーを処理しない
   - HTTP エラー（404, 500）を検出しない
   - JSON パースエラーを処理しない

3. **Effective TypeScript Item 4 違反** - any 型を避けるべき

### 改善版

\`\`\`typescript
interface UserData {
  name: string;
  email: string;
  age?: number;
}

interface SaveUserResponse {
  id: string;
  success: boolean;
}

async function saveUser(
  userData: UserData  // 型安全に指定
): Promise<SaveUserResponse> {
  try {
    const response = await fetch('/api/users', {
      method: 'POST',
      body: JSON.stringify(userData),
    });

    // HTTP エラーをチェック
    if (!response.ok) {
      throw new Error(\`HTTP \${response.status}: \${response.statusText}\`);
    }

    const result = await response.json() as SaveUserResponse;
    return result;
  } catch (error) {
    // エラーを適切に処理
    if (error instanceof TypeError) {
      throw new Error('Network error: Failed to reach the server');
    }
    throw error;  // 呼び元で処理
  }
}
\`\`\`

### 改善点

✅ パラメータと戻り値に型を指定
✅ HTTP エラー（response.ok）をチェック
✅ try/catch でエラーハンドリング
✅ ネットワークエラーと HTTP エラーを区別
✅ Effective TypeScript に準拠

### 参考
- Effective TypeScript Item 38（any 型を避ける）
- Effective TypeScript Item 31（エラーハンドリング）
```

**生成ロジック:**
1. コード例を提示（問題あり）
2. 複数の問題点を列挙
3. 改善版コードを提示
4. 改善理由を説明
5. ベストプラクティスを参照

---

### 4️⃣ デバッグ問題

**用途**: 問題解決能力、デバッグスキル

**例:**
```markdown
## 問題 4: デバッグ - 型エラー

以下のコードにはバグがあります。問題を特定し、修正してください。

### バグあり版
\`\`\`typescript
async function processUsers(userIds: number[]) {
  const users = await Promise.all(
    userIds.map(id => fetchUser(id))  // Promise[] を返す
  );

  users.forEach(user => {
    console.log(user.name);  // エラー！user が User | Error の可能性
  });

  return users;
}
\`\`\`

### エラーメッセージ
```
error TS2339: Property 'name' does not exist on type 'User | Error'.
```

### 根本原因

`Promise.allSettled()` を使わずに `Promise.all()` を使っているため、
1 つのプロミスが rejected すると、Promise.all() 全体が失敗します。

ただし上記の場合、`Promise.all()` が成功していれば users は `User[]` のはずなのに、
型チェッカーが警告しています。実装側の型定義が曖昧です。

### 修正版

\`\`\`typescript
async function processUsers(
  userIds: number[]
): Promise<User[]> {
  // 複数のプロミスを並列実行
  const users = await Promise.all(
    userIds.map(id => fetchUser(id))
  );

  // 型チェッカーが User[] を確認できるように明示的に型注釈
  users.forEach((user: User) => {
    console.log(user.name);  // OK
  });

  return users;
}

// または、エラー処理を含める場合
async function processUsersWithErrorHandling(
  userIds: number[]
): Promise<(User | Error)[]> {
  // 1 つのエラーでも続行したい場合は allSettled
  const results = await Promise.allSettled(
    userIds.map(id => fetchUser(id))
  );

  return results.map(result =>
    result.status === 'fulfilled' ? result.value : result.reason
  );
}
\`\`\`

### 修正理由

1. **Promise.all() vs Promise.allSettled()**
   - `all()`: 1 つのエラーで全体が失敗。すべて成功する場合のみ推奨
   - `allSettled()`: すべてのプロミス結果を取得（成功・失敗混在）

2. **型注釈の明示**
   - 戻り値を `Promise<User[]>` と明示して型チェッカーをサポート

3. **エラー処理パターン**
   - strict なエラー処理が必要な場合は `allSettled` + エラー型の Union

### 参考
- TypeScript Handbook: Promise.all vs Promise.allSettled
- Effective TypeScript Item 35（async 関数の扱い）
```

**生成ロジック:**
1. バグあり版コードを提示
2. エラーメッセージを表示
3. 根本原因を説明
4. 修正版を提示
5. 修正理由を詳しく説明

---

## ⚙️ スキルのカスタマイズパラメータ

```json
{
  "topic": "async/Promise",            // 技術分野
  "difficulty": "medium",              // 難易度
  "problemType": "coding",             // 問題タイプ
  "count": 3,                          // 生成問題数

  "learnerLevel": "senior",            // ジュニア/シニア/プロ
  "focusOnWeakAreas": true,           // 弱点分野を重視
  "recentTopics": ["async"],          // 最近学習した内容
  "excludeTopics": [],                // 除外する分野

  "bestPractices": {
    "includeEffectiveTypeScript": true,  // Effective TypeScript を組み込む
    "includeTypeScript5x": true,         // TypeScript 5.x 新機能を含める
    "includeAWSPatterns": true,          // AWS CDK v2 パターンを含める
    "typescriptVersion": "5.3+"         // TypeScript 最新版対応
  },

  "references": {
    "includeDocumentation": true,       // 公式ドキュメントへのリンク
    "includeTypeChallenge": true,       // TypeChallenge への入口を示す
    "includeBestPracticesLinks": true   // ベストプラクティス資料へのリンク
  }
}
```

---

## 📖 使用例

### 基本的な使用

```
「typescript-quiz-generator で以下の問題を生成してください：
 - 分野: async/Promise
 - 難易度: 中級
 - 問題タイプ: 記述問題
 - 数: 3 問」
```

### ジュニア向けカスタマイズ

```
「typescript-quiz-generator で以下の問題を生成：
 - 分野: async/await の基本
 - 学習者レベル: ジュニア（基礎を重視）
 - 難易度: easy
 - 問題数: 5 問（1 日 1 問ペース）
 - ベストプラクティス: Effective TypeScript の基本原則を含める」
```

### シニア向け集中特訓

```
「typescript-quiz-generator で以下を実施：
 - 弱点分野: エラーハンドリング
 - 難易度: medium～hard
 - 問題タイプ: 記述問題とレビュー問題の混合
 - AWS 統合: Lambda + DynamoDB のシナリオを含める
 - 参考資源: AWS CDK 公式ドキュメント、TypeScript Handbook を含める」
```

### TypeChallenge 準備

```
「typescript-quiz-generator で以下の問題セットを生成：
 - テーマ: 高度な型定義（条件付き型、型推論）
 - 難易度: hard
 - 形式: 4 択 + 記述混合
 - TypeChallenge レベル: easy～medium への橋渡し
 - 複雑な Generic パターンを多数含める」
```

---

## 🔄 問題生成フロー

```
1. パラメータ受け取り
   ↓
2. 前提条件チェック
   ├─ ファイル形式確認
   ├─ パラメータ検証
   └─ 設定ファイル読み込み
   ↓
3. テンプレート選択
   └─ 問題タイプ別テンプレート選択
   ↓
4. ベストプラクティス統合
   ├─ Effective TypeScript の原則を組み込む
   ├─ TypeScript 5.x 新機能を反映
   ├─ AWS CDK v2 パターンを含める
   └─ 参考資源を自動追加
   ↓
5. コンテンツ生成
   ├─ 問題文生成
   ├─ コード例生成
   ├─ 複数の解答例を生成
   └─ 詳細な解説を作成
   ↓
6. Markdown フォーマット
   ├─ 見出しレベル設定
   ├─ コードブロック言語指定
   ├─ テーブル・リスト整形
   └─ 参考リンク追加
   ↓
7. 出力
   └─ 問題セット（Markdown 形式）
```

---

## ✨ 特徴・強み

### 1. 汎用性
- TypeScript だけでなく、他の技術領域への拡張可能
- 新しい問題タイプを簡単に追加可能

### 2. 最新ベストプラクティス準拠
- Effective TypeScript の 83 項目を参照
- TypeScript 5.x の最新機能を含める
- AWS CDK v2 の推奨パターンを組み込む

### 3. 学習効果最大化
- 学習者レベルに応じたカスタマイズ
- 弱点分野を重点的に出題
- 複数の実装パターンを提示

### 4. 拡張可能な設計
- JSON 設定ファイルで問題パラメータを管理
- テンプレートを追加して新しい形式に対応
- ベストプラクティスの更新が容易

---

## 🔮 今後の拡張予定

- [ ] React + TypeScript への対応
- [ ] Next.js 特化的な問題生成
- [ ] GraphQL + TypeScript
- [ ] Nest.js フレームワーク
- [ ] テスト駆動開発（TDD）の教育
- [ ] パフォーマンス最適化ガイド
- [ ] マルチテナント設計パターン

---

**このスキルは、TypeScript プロフェッショナルレベルへの成長を支援します。**
