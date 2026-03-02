---
name: aws-lambda-typescript
description: AWS Lambda (TypeScript) のベストプラクティスガイド。API Gateway、EventBridge、SQS等の実装パターン、DynamoDB操作、エラーハンドリング、Powertools活用、パフォーマンス最適化を含む包括的なガイド。
context: fork
---

# AWS Lambda (TypeScript) ベストプラクティス

Lambda関数を実装・レビューする際のガイドラインです。

## Lambda設計原則

### 単一責任の原則

ハンドラーは「イベントの受信とレスポンスの返却」のみに責任を持つ。ビジネスロジックは別の関数・クラスに分離。

### レイヤードアーキテクチャ

責務を3層に分離することで、テスト容易性と保守性が向上：

- **Handler層**: イベント受信、パース、バリデーション、レスポンス生成
- **UseCase層**: ビジネスロジック（ドメイン知識を含む処理）
- **Repository層**: データ永続化（DynamoDB、RDS等）

```typescript
// Handler層（handler.ts）
export const handler = async (event: APIGatewayProxyEvent) => {
  const body = parseJSON(event.body)
  const result = await createOrderUseCase.execute(body)
  return createResponse(200, result)
}

// UseCase層（createOrderUseCase.ts）
class CreateOrderUseCase {
  constructor(private orderRepository: OrderRepository) {}
  async execute(input: CreateOrderInput): Promise<Order> {
    if (input.amount <= 0) throw new DomainError('Amount must be positive')
    return await this.orderRepository.save(input)
  }
}
```

### エラーハンドリング戦略

エラーを2種類に分類し、適切なHTTPステータスコードを返す：

- **ドメインエラー**: ビジネスルール違反（400, 403等）
- **システムエラー**: インフラ障害（500）

### 依存性注入パターン

テスト容易性のため、依存オブジェクトはhandler外で初期化し注入可能にする。

## 呼び出し元に応じた戻り値

| 呼び出し元 | 戻り値 |
|-----------|--------|
| API Gateway / ALB | `{ statusCode: number; headers?: object; body: string }` |
| EventBridge / スケジューラー | `Promise<void>`（例外はそのまま投げる） |
| SQS / SNS | `Promise<void>` または `SQSBatchResponse` |
| 同期呼び出し（Invoke） | 任意のJSON |

## クライアント・インスタンス初期化

SDK クライアントや依存オブジェクトは **handler の外** でインスタンス化（ウォームスタートで再利用）：

```typescript
import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb'

const dynamoDb = DynamoDBDocumentClient.from(new DynamoDBClient({}))
const repository = new SessionRepository()
const useCase = new GetSessionUseCase(repository)

export const handler = async (event) => {
  // dynamoDb, repository, useCase を使用
}
```

## 主要トピック一覧

以下の詳細なコード例・パターンは `references/detailed-patterns.md` を参照：

- **API Gateway 経由の Lambda**: 汎用実装パターン、リクエストバリデーション、パスパラメータ
- **DynamoDB 操作**: Scan/Query (paginateScan)、書き込み/削除、楽観的ロック
- **エラーハンドリング**: API Gateway経由、非同期呼び出し (EventBridge/SQS)
- **環境変数**: 必須変数のバリデーション、型安全な取得関数
- **非同期処理の注意点**: Fire-and-forget の危険性、Promise.all
- **ロールバック・補償処理**: Saga パターン
- **AWS Lambda Powertools**: Logger, Metrics, Tracer, Parameters, Idempotency
- **Lambda SnapStart**: コールドスタート90%削減
- **ESM (ECMAScript Modules)**: Top-level await、注意事項
- **コストとパフォーマンスの最適化**: Graviton2 (arm64)、Power Tuning
- **セキュリティの強化**: 最小権限の原則、シークレット管理
- **ローカルデバッグ**: tsx, AWS SAM CLI, SST
- **IaC**: AWS CDK, SAM, Serverless Framework
- **サードパーティライブラリ**: middy, zod

## その他のベストプラクティス

- **構造化ログ**: 不要な `console.log` は避け、Powertools Loggerを推奨
- **冪等性**: 必要な場合は明示的に設計（Powertools Idempotency推奨）
- **タイムアウト**: 処理内容に応じて適切に設定
- **型定義**: `aws-lambda` パッケージの型を使用
  - `APIGatewayProxyEvent`, `APIGatewayProxyResult`
  - `EventBridgeEvent`, `SQSEvent`, `SQSBatchResponse`
