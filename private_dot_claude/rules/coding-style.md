---
paths:
  - "**/*.{ts,tsx,js,jsx,py,go,rs,java,kt,swift,c,cpp,h,hpp,cs,rb,php}"
---

# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate:

```javascript
// WRONG: Mutation
function updateUser(user, name) {
  user.name = name  // MUTATION!
  return user
}

// CORRECT: Immutability
function updateUser(user, name) {
  return {
    ...user,
    name
  }
}
```

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large components
- Organize by feature/domain, not by type

## Error Handling

ALWAYS handle errors comprehensively:

```typescript
try {
  const result = await riskyOperation()
  return result
} catch (error) {
  console.error('Operation failed:', error)
  throw new Error('Detailed user-friendly message')
}
```

## Input Validation

ALWAYS validate user input:

```typescript
import { z } from 'zod'

const schema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150)
})

const validated = schema.parse(input)
```

## Comments

情報には置き場所がある。置き場所を間違えた情報は、読み手が探しても見つからないか、
古くなって嘘になる。

| 置き場所 | 書くこと | 具体的には |
|---------|---------|----------|
| コード | How | どうやって実現しているか |
| テストコード | What | 何が起きるのが正しいか |
| コミットログ・PR | Why | なぜこの変更が必要だったか |
| コードコメント | **Why not** | なぜ他のやり方を採らなかったか |

コードコメントに置くのは「あえてやっていないこと」。やっていることはコードが語るため、
重ねて書くと二重管理になる。

### コメントを書く前に

コードとコメントは別々に変更されるため、コメントは必ず古くなる。書く前に、
コードでの表現に置き換えられないか順に試す。

1. 名前を変えて説明が要らなくならないか（`code-naming` スキル）
2. 処理をひとまとまりの関数に切り出して、関数名で説明できないか
3. 途中の式を、意味のある名前の変数に受けられないか
4. 定数に名前を付けられないか

### 書くこと（Why not）

コードを読んでも分からず、その場所を触る人が必ず知る必要があることだけ。

- あえてやっていないこと（意図的に無い処理）
- 一見不自然な書き方の理由（外部仕様の制約・既知不具合の回避・性能上の妥協）
- 採用しなかった代替案とその理由（後からの再検討を防ぐ）
- 制約の出典（公式ドキュメント URL・Issue 番号・実測結果）

```typescript
// ここでリトライしないのは、呼び出し先が冪等でないため。
// 二重実行になるより、失敗を上位に返すほうが安全（Issue #123 の議論による）。

// 500 件ずつに分けているのは、SDK が 1 回あたり 500 件を超えると
// 例外を投げるため（https://example.com/docs/batch ）。
```

### 書かないこと

| 書かないもの | 理由 |
|------------|------|
| コードをなぞる説明（WHAT） | コードを変えたときに必ず食い違う |
| 変更履歴・作成日・作成者・PR/タスクID | バージョン管理が持っている情報 |
| コメントアウトしたコード | 消す。必要ならバージョン管理から戻せる |
| 引数名を並べただけの定型的な説明 | 情報量がなく、読み飛ばす習慣を作る |
| 期限も担当も無い TODO | Issue にする。コードに残すと放置される |

### テストコード（What）

テストは仕様書として読まれる。**テスト名だけを並べて読んだときに、
その機能が何をするものか分かる状態**にする。

- 名前に「どういう状態で」「何をすると」「どうなる」を入れる
- 1つのテストで検証する結果は、読み手が1文で言える範囲に収める
- テスト本体に How を書きすぎない
- 期待値の理由が自明でないときだけコメントを添える

### コミットログ・PR（Why）

何を変えたかは差分が語る。なぜ変えたかは差分から読めない。

- 表題は変更内容を1行で
- 本文に必要性と解決する問題
- 設計判断なら、選んだ案と棄却した案、その理由
- Issue 番号・ドキュメント URL などの出典

### 設計文書の判断理由をどこに残すか

実装計画や設計文書は実装後に古くなる。判断理由は移す。

| 理由の性質 | 移す先 |
|-----------|--------|
| その行・ブロックを触る人が必ず知る必要がある | コードコメント |
| 変更全体の背景で、個々の行に紐づかない | コミットログ・PR 本文 |
| どちらにも当てはまらない | 移さない（実装後は不要） |

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No console.log statements
- [ ] No hardcoded values
- [ ] No mutation (immutable patterns used)
- [ ] コードの内容をそのまま日本語にしただけのコメントが残っていない
- [ ] コメントで説明している内容を、名前変更や関数切り出しで消せない
- [ ] 制約や妥協の理由に出典（URL・Issue 番号・実測結果）が付いている
- [ ] テスト名だけを並べて読んで仕様が分かる
- [ ] コミットログ・PR 本文に「なぜ」が書かれている
