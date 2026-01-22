---
name: aws-lambda-typescript
description: AWS Lambda (TypeScript) のベストプラクティスガイド。API Gateway、EventBridge、SQS等の実装パターン、DynamoDB操作、エラーハンドリング、Powertools活用、パフォーマンス最適化を含む包括的なガイド。
context: fork
---

# AWS Lambda (TypeScript) ベストプラクティス

Lambda関数を実装・レビューする際のガイドラインです。

## Lambda設計原則

### 単一責任の原則

ハンドラーは「イベントの受信とレスポンスの返却」のみに責任を持つ。ビジネスロジックは別の関数・クラスに分離：

```typescript
// ❌ Bad: ハンドラーにビジネスロジックが混在
export const handler = async (event: APIGatewayProxyEvent) => {
  const body = JSON.parse(event.body!)
  const user = await dynamodb.get({ TableName: 'Users', Key: { id: body.userId } })
  if (!user || user.status !== 'active') {
    return { statusCode: 403, body: 'Forbidden' }
  }
  // さらに複雑な処理が続く...
}

// ✅ Good: ハンドラーはシンプルに、ビジネスロジックは分離
export const handler = async (event: APIGatewayProxyEvent) => {
  const body = parseJSON(event.body)
  const result = await createOrderUseCase.execute(body)
  return createResponse(200, result)
}
```

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
    // ビジネスルールの検証
    if (input.amount <= 0) {
      throw new DomainError('Amount must be positive')
    }

    // データ永続化
    return await this.orderRepository.save(input)
  }
}

// Repository層（orderRepository.ts）
class OrderRepository {
  async save(order: CreateOrderInput): Promise<Order> {
    // DynamoDB操作
    await dynamodb.send(new PutCommand({ TableName: 'Orders', Item: order }))
    return order
  }
}
```

### エラーハンドリング戦略

エラーを2種類に分類し、適切なHTTPステータスコードを返す：

- **ドメインエラー**: ビジネスルール違反（400 Bad Request、403 Forbidden等）
- **システムエラー**: インフラ障害、予期しないエラー（500 Internal Server Error）

```typescript
// カスタムエラークラス
class DomainError extends Error {
  constructor(message: string, public statusCode: number = 400) {
    super(message)
    this.name = 'DomainError'
  }
}

// エラーハンドリング
function handleError(error: unknown): APIGatewayProxyResult {
  if (error instanceof DomainError) {
    // ドメインエラー: ユーザーに理由を返す
    return createResponse(error.statusCode, { message: error.message })
  }

  // システムエラー: 詳細を隠す
  console.error('System error:', error)
  return createResponse(500, { message: 'Internal server error' })
}
```

### 依存性注入パターン

テスト容易性のため、依存オブジェクトは外部から注入可能にする：

```typescript
// ❌ Bad: handler内で直接インスタンス化（テストが困難）
export const handler = async (event: APIGatewayProxyEvent) => {
  const repository = new OrderRepository() // ハードコーディング
  const useCase = new CreateOrderUseCase(repository)
  return await useCase.execute(event.body)
}

// ✅ Good: handler外で初期化（テスト時にモックを注入可能）
const repository = new OrderRepository()
const useCase = new CreateOrderUseCase(repository)

export const handler = async (event: APIGatewayProxyEvent) => {
  const body = parseJSON(event.body)
  const result = await useCase.execute(body)
  return createResponse(200, result)
}
```

**テスト例**:
```typescript
// テスト時はモックを注入
const mockRepository = {
  save: jest.fn().mockResolvedValue({ id: '123', status: 'pending' })
}
const useCase = new CreateOrderUseCase(mockRepository)
```

---

## 呼び出し元に応じた戻り値

| 呼び出し元 | 戻り値 |
|-----------|--------|
| API Gateway / ALB | `{ statusCode: number; headers?: object; body: string }` |
| EventBridge / スケジューラー | `Promise<void>`（例外はそのまま投げる） |
| SQS / SNS | `Promise<void>` または `SQSBatchResponse` |
| 同期呼び出し（Invoke） | 任意のJSON |

---

## クライアント・インスタンス初期化

SDK クライアントや依存オブジェクトは **handler の外** でインスタンス化（ウォームスタートで再利用）：

```typescript
// ✅ Good: handler外でインスタンス化
import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb'

const dynamoDb = DynamoDBDocumentClient.from(new DynamoDBClient({}))
const repository = new SessionRepository()
const useCase = new GetSessionUseCase(repository)

export const handler = async (event) => {
  // dynamoDb, repository, useCase を使用
}
```

---

## API Gateway 経由の Lambda

### 汎用実装パターン（生のTypeScript）

リクエストパース、バリデーション、エラーハンドリングなどを明示的に実装：

```typescript
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda'

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // 1. JSONパース（エラーハンドリング付き）
    const body = parseJSON(event.body)

    // 2. バリデーション
    const validationResult = validateRequest(body)
    if (!validationResult.valid) {
      return createResponse(400, { errors: validationResult.errors })
    }

    // 3. ビジネスロジック実行
    const result = await executeBusinessLogic(validationResult.data)

    // 4. レスポンス生成（セキュリティヘッダー付き）
    return createResponse(200, result)
  } catch (error) {
    return handleError(error)
  }
}

// ヘルパー関数: JSONパース
function parseJSON(body: string | null): unknown {
  if (!body) {
    throw new Error('Request body is empty')
  }
  try {
    return JSON.parse(body)
  } catch (error) {
    throw new Error('Invalid JSON format')
  }
}

// ヘルパー関数: レスポンス生成
function createResponse(statusCode: number, body: unknown): APIGatewayProxyResult {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
    },
    body: JSON.stringify(body),
  }
}

// ヘルパー関数: エラーハンドリング
function handleError(error: unknown): APIGatewayProxyResult {
  console.error('Error:', error)
  const message = error instanceof Error ? error.message : 'Internal server error'
  return createResponse(500, { message })
}
```

### リクエストバリデーション

TypeScript型ガードとカスタムバリデーション関数による実装：

```typescript
// リクエストボディの型定義
interface RequestBody {
  imageId: string
  cpu?: number
}

// 型ガード（型安全な検証）
function isValidRequestBody(body: any): body is RequestBody {
  return (
    typeof body === 'object' &&
    body !== null &&
    typeof body.imageId === 'string' &&
    body.imageId.length > 0 &&
    (body.cpu === undefined || (typeof body.cpu === 'number' && body.cpu > 0))
  )
}

// 詳細なバリデーション（エラーメッセージ付き）
function validateRequest(
  body: any
): { valid: true; data: RequestBody } | { valid: false; errors: string[] } {
  const errors: string[] = []

  if (typeof body !== 'object' || body === null) {
    errors.push('Request body must be an object')
    return { valid: false, errors }
  }

  if (typeof body.imageId !== 'string' || body.imageId.length === 0) {
    errors.push('imageId must be a non-empty string')
  }

  if (body.cpu !== undefined && (typeof body.cpu !== 'number' || body.cpu <= 0)) {
    errors.push('cpu must be a positive number')
  }

  if (errors.length > 0) {
    return { valid: false, errors }
  }

  return { valid: true, data: body as RequestBody }
}
```

### 選択肢: ライブラリを使用する場合

上記は標準TypeScriptでの実装例ですが、以下のライブラリを使用することで開発効率を向上できます：

- **middy**: ミドルウェアフレームワーク（詳細は「オプション: サードパーティライブラリ」セクション参照）
- **zod / Joi / yup**: スキーマバリデーションライブラリ（詳細は同上）

### パスパラメータの取得

```typescript
const sessionId = event.pathParameters?.id
if (!sessionId) {
  return { statusCode: 400, body: JSON.stringify({ message: 'sessionId is required' }) }
}
```

### レスポンスヘルパー（オプション）

共通フォーマットがある場合はヘルパーを用意：

```typescript
export function createResponse(
  statusCode: number,
  body: unknown,
  additionalHeaders: Record<string, string> = {}
): APIGatewayProxyResult {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json', ...additionalHeaders },
    body: typeof body === 'string' ? body : JSON.stringify(body),
  }
}
```

---

## DynamoDB 操作

### Scan / Query

- **自前のページネーションループは書かない**
- SDK v3 の `paginateScan` / `paginateQuery` を使用

```typescript
import { paginateScan, DynamoDBClient } from '@aws-sdk/client-dynamodb'

const client = new DynamoDBClient({})

for await (const page of paginateScan({ client }, { TableName: 'table' })) {
  for (const item of page.Items ?? []) {
    // 処理
  }
}
```

### 書き込み / 削除

- **大量データでなければシンプルなループを優先**
- `BatchWriteItem` の `UnprocessedItems` 処理は複雑なので、要件上必須でなければ `PutItem` / `DeleteItem` のループでOK
- スループット制限が厳しい場合のみバッチ処理を検討

### 楽観的ロック（条件付き更新）

競合を防ぐ場合は `ConditionExpression` を使用：

```typescript
await dynamoDb.send(
  new UpdateCommand({
    TableName: TABLE_NAME,
    Key: { id: itemId },
    UpdateExpression: 'SET #status = :newStatus',
    ConditionExpression: '#status = :expectedStatus',
    ExpressionAttributeNames: { '#status': 'status' },
    ExpressionAttributeValues: {
      ':newStatus': 'active',
      ':expectedStatus': 'pending',
    },
  }),
)
```

---

## エラーハンドリング

### API Gateway 経由

try-catch で適切な statusCode を返す：

```typescript
try {
  const result = await useCase.execute(input)
  return { statusCode: 200, body: JSON.stringify(result) }
} catch (error) {
  console.error('Error:', error)
  return {
    statusCode: 500,
    body: JSON.stringify({ message: getErrorMessage(error) }),
  }
}
```

### 非同期呼び出し（EventBridge / SQS）

例外をそのまま投げる（Lambda がリトライ / DLQ で処理）：

```typescript
export const handler = async (event: EventBridgeEvent<string, Payload>): Promise<void> => {
  await processEvent(event.detail)
  // エラー時はそのままthrow → Lambda がリトライ/DLQ処理
}
```

### エラーメッセージ取得ヘルパー

```typescript
export function getErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error)
}
```

---

## 環境変数

### 必須変数のバリデーション

handler 冒頭または初期化時に検証。欠損時は明確なエラーで早期終了：

```typescript
const tableName = process.env.TABLE_NAME
if (!tableName) throw new Error('TABLE_NAME is required')
```

### 型安全な取得関数

```typescript
export function getEnv(key: string, defaultValue?: string): string {
  const value = process.env[key]
  if (!value && !defaultValue) {
    throw new Error(`Environment variable ${key} is not set`)
  }
  return value || defaultValue!
}
```

### オプショナル変数はデフォルト値を設定

```typescript
const port = process.env.PORT ? Number.parseInt(process.env.PORT, 10) : 8080
const maxRetries = process.env.MAX_RETRIES ? Number(process.env.MAX_RETRIES) : 3
```

---

## 非同期処理の注意点

### Fire-and-forget パターンの危険性

レスポンス後に完了を待たない処理は、エラーログを忘れずに。**Lambda実行が終了する前に全ての非同期処理が完了していることを保証する**必要があります：

```typescript
// ⚠️ 注意: レスポンス返却後も非同期で監視（完了を待たない）
checkStatusAsync(commandId)
  .then((output) => {
    console.log('Command completed:', output)
  })
  .catch((error) => {
    console.error('Command failed:', getErrorMessage(error))
    // 必要に応じて補償処理
  })

return { statusCode: 202, body: JSON.stringify({ id: commandId }) }
```

### Promise.all による完了保証

```typescript
// ✅ Good: 全ての非同期処理の完了を待つ
const [result1, result2] = await Promise.all([
  operation1(),
  operation2(),
])

return { statusCode: 200, body: JSON.stringify({ result1, result2 }) }
```

---

## ロールバック・補償処理

部分的に成功した操作の後処理は、エラー発生時に明示的に実行：

```typescript
let resourceAllocated = false
try {
  await allocateResource()
  resourceAllocated = true

  await saveToDatabase() // ここでエラーが発生する可能性
} catch (error) {
  if (resourceAllocated) {
    await releaseResource().catch((e) => {
      console.warn('Rollback failed:', getErrorMessage(e))
    })
  }
  throw error
}
```

複雑な分散トランザクションには **AWS Step Functions の Saga パターン** を検討してください。

---

## AWS Lambda Powertools for TypeScript（推奨）

**最重要**: Powertoolsは観測性（Observability）とベストプラクティスを劇的に改善します。

### インストール

```bash
npm install @aws-lambda-powertools/logger @aws-lambda-powertools/metrics @aws-lambda-powertools/tracer
```

### Logger（構造化ログ）

```typescript
import { Logger } from '@aws-lambda-powertools/logger'

const logger = new Logger({ serviceName: 'myService' })

export const handler = async (event) => {
  logger.info('Processing event', { eventId: event.id })

  try {
    const result = await processEvent(event)
    logger.info('Event processed successfully', { result })
    return result
  } catch (error) {
    logger.error('Event processing failed', error as Error)
    throw error
  }
}
```

### Metrics（カスタムメトリクス）

EMF (Embedded Metric Format) 形式で非同期出力し、パフォーマンスへの影響を最小化：

```typescript
import { Metrics, MetricUnits } from '@aws-lambda-powertools/metrics'

const metrics = new Metrics({ namespace: 'MyApp', serviceName: 'myService' })

export const handler = async (event) => {
  metrics.addMetric('SuccessfulInvocations', MetricUnits.Count, 1)

  const result = await processEvent(event)

  metrics.publishStoredMetrics()
  return result
}
```

### Tracer（AWS X-Ray）

```typescript
import { Tracer } from '@aws-lambda-powertools/tracer'

const tracer = new Tracer({ serviceName: 'myService' })

export const handler = async (event) => {
  const segment = tracer.getSegment()
  const subsegment = segment.addNewSubsegment('ProcessEvent')

  try {
    const result = await processEvent(event)
    subsegment.close()
    return result
  } catch (error) {
    subsegment.close(error)
    throw error
  }
}
```

### Parameters（シークレット管理）

AWS Systems Manager Parameter Store や Secrets Manager からパラメータを効率的に取得・キャッシュ：

```typescript
import { getParameter } from '@aws-lambda-powertools/parameters/ssm'

const dbPassword = await getParameter('/myapp/database/password', {
  maxAge: 300, // 5分間キャッシュ
  transform: 'json',
})
```

### Idempotency（冪等性）

重複実行を防ぎ、同じリクエストに対して常に同じ結果を返す：

```typescript
import { makeIdempotent } from '@aws-lambda-powertools/idempotency'
import { DynamoDBPersistenceLayer } from '@aws-lambda-powertools/idempotency/dynamodb'

const persistenceStore = new DynamoDBPersistenceLayer({
  tableName: 'IdempotencyTable',
})

const handler = async (event) => {
  // 処理
  return { statusCode: 200, body: 'Success' }
}

export const lambdaHandler = makeIdempotent(handler, {
  persistenceStore,
  config: {
    eventKeyJmesPath: 'body.requestId', // 冪等性キーのパス
  },
})
```

---

## Lambda SnapStart for Node.js

**コールドスタートを最大90%削減**する強力な機能。関数バージョン発行時に初期化フェーズのスナップショットを作成し、リストアすることで起動を高速化します。

### 有効化方法

AWS CDK:
```typescript
new lambda.Function(this, 'MyFunction', {
  runtime: lambda.Runtime.NODEJS_20_X,
  snapStart: lambda.SnapStartConf.ON_PUBLISHED_VERSIONS,
  // ...
})
```

### 注意事項

初期化時に生成されるユニークなIDや、確立されたネットワーク接続は、リストア後には古くなっている可能性があります。

```typescript
import { SnapStart } from '@aws-lambda-powertools/commons'

// スナップショット作成前に実行
SnapStart.beforeCheckpoint(async () => {
  console.log('Creating snapshot...')
  // 接続をクローズするなど
})

// リストア後に実行
SnapStart.afterRestore(async () => {
  console.log('Restoring from snapshot...')
  // 新しいUUIDを生成、接続を再確立するなど
})
```

---

## ECMAScript Modules (ESM)

Node.js 16以降のランタイムではESMが標準的にサポートされています。

### 有効化

`package.json` に `"type": "module"` を追加：

```json
{
  "type": "module",
  "main": "index.js"
}
```

### Top-level await の使用

```typescript
// ✅ ESMではトップレベルでawaitが使える
const config = await fetchConfig()

export const handler = async (event) => {
  // ...
}
```

### 注意事項

- `require()` は使えません（`import` を使用）
- `__dirname` と `__filename` は使えません（`import.meta.url` を使用）

```typescript
import { fileURLToPath } from 'node:url'
import { dirname } from 'node:path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)
```

---

## コストとパフォーマンスの最適化

### Graviton2 (arm64) アーキテクチャ

多くの場合、x86アーキテクチャよりも高いコストパフォーマンスを実現：

```typescript
new lambda.Function(this, 'MyFunction', {
  runtime: lambda.Runtime.NODEJS_20_X,
  architecture: lambda.Architecture.ARM_64, // Graviton2
  // ...
})
```

### Lambda Power Tuning

最適なメモリサイズ（=CPU性能）を見つけるためのツール：

- [AWS Lambda Power Tuning](https://github.com/alexcasalboni/aws-lambda-power-tuning)
- コストと実行時間のバランスを可視化

---

## セキュリティの強化

### 最小権限の原則

Lambda関数にアタッチするIAMロールは、本当に必要なアクション（例: `dynamodb:GetItem`）とリソース（例: 特定のテーブルのARN）のみに限定：

```typescript
new iam.PolicyStatement({
  actions: ['dynamodb:GetItem', 'dynamodb:PutItem'],
  resources: ['arn:aws:dynamodb:region:account:table/MyTable'],
})
```

### シークレット管理

データベースのパスワードなどの機密情報は、環境変数に直接書き込むのではなく、**AWS Secrets Manager** や **Parameter Store** で管理し、実行時に取得：

```typescript
import { getSecret } from '@aws-lambda-powertools/parameters/secrets'

const dbCredentials = await getSecret('myapp/database/credentials', {
  transform: 'json',
})
```

---

## ローカルデバッグ

Lambda関数のローカルデバッグは、目的に応じて複数のツールを使い分けるのが2025年時点のベストプラクティスです。

### デバッグ手法の使い分け

| フェーズ | 目的 | 推奨ツール |
|---------|------|-----------|
| **ユニットテスト** | ビジネスロジックの単体検証（高速・隔離） | **vitest / jest** |
| **ローカル手動実行** | 開発初期の素早い動作確認 | **tsx** |
| **ローカル統合テスト** | Lambda実行環境やトリガーを含めたテスト | **AWS SAM CLI** |
| **クラウド連携デバッグ** | IAM権限や他サービス連携を含む完全なテスト | **SST Live Lambda Development** |

### tsx による手動実行

**用途**: 開発初期の迅速な動作確認、ロジックの単体検証

#### 実行方法

```bash
npx tsx src/lambda/handlers/create-session.ts
```

#### ハンドラーに直接実行用コードを追加

ESM の `import.meta.url` を使ってエントリポイント判定：

```typescript
import { fileURLToPath } from 'node:url'
import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda'

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  // ... ハンドラー実装
}

// ローカルデバッグ用（tsx で直接実行時のみ動作）
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const mockEvent: APIGatewayProxyEvent = {
    body: JSON.stringify({
      imageId: 'test-image',
      cpu: 2,
    }),
    headers: { 'Content-Type': 'application/json' },
    multiValueHeaders: {},
    httpMethod: 'POST',
    isBase64Encoded: false,
    path: '/sessions/request',
    pathParameters: null,
    queryStringParameters: null,
    multiValueQueryStringParameters: null,
    stageVariables: null,
    requestContext: {} as any,
    resource: '',
  }

  handler(mockEvent, {} as Context)
    .then((result) => console.log('Success:', JSON.stringify(result, null, 2)))
    .catch((error) => console.error('Error:', error))
}
```

#### ポイント

- ✅ `process.argv[1] === fileURLToPath(import.meta.url)` で直接実行時のみ動作
- ✅ Lambda デプロイ時はこのブロックは実行されない
- ✅ 環境変数が必要な場合は `.env` + `dotenv` または実行時に指定

```bash
DB_CLUSTER_ARN=xxx DB_SECRET_ARN=yyy npx tsx src/lambda/handlers/create-session.ts
```

#### 限界

- ⚠️ Lambda実行環境をエミュレートしていない（IAMロール、メモリ制限、タイムアウト等は適用されない）
- ⚠️ ローカルのAWS認証情報（`~/.aws/credentials`）に依存
- ⚠️ 関数のロジック単体の検証には最適だが、AWS環境全体との結合テストには不十分

### AWS SAM CLI による統合テスト

**用途**: 本番に近い環境でのローカル統合テスト

AWS公式ツール。Dockerコンテナ上で本番とほぼ同じLambda実行環境をエミュレートします。

#### インストール

```bash
# Homebrew (macOS/Linux)
brew install aws-sam-cli

# または公式インストーラー
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
```

#### 使用方法

```bash
# 単一の関数を起動
sam local invoke MyFunction -e events/test-event.json

# API Gatewayをローカルで起動
sam local start-api

# Lambda関数とAPI Gatewayを同時起動
sam local start-lambda
```

#### ポイント

- ✅ Dockerベースで本番Lambdaランタイムと同じ環境
- ✅ Node.jsバージョンやシステムライブラリの違いを防ぐ
- ✅ CI/CDパイプラインでの統合テストに最適
- ⚠️ Docker環境が必要

### SST によるクラウド連携デバッグ（参考）

**用途**: IAM権限や他サービス連携を含む完全なデバッグ

**SST (Serverless Stack)** の **Live Lambda Development** は、コードをローカルで実行しつつ、リクエストは実際のAWS環境から受け取る画期的な機能です。

#### 特徴

- ✅ 本物のAWS環境（API Gateway, SQS等）からリクエストを受信
- ✅ IAM権限や他サービスとの連携を実際の環境でデバッグ可能
- ✅ VPC内リソースへの接続問題も検証できる
- ⚠️ プロジェクトでSSTを採用している場合のみ利用可能

詳細: [SST Live Lambda Development](https://sst.dev/)

---

## IaC（Infrastructure as Code）によるデプロイ

手動でのコンソール操作によるデプロイは避け、インフラストラクチャをコードで管理（IaC）することが強く推奨されます。

### AWS CDK (Cloud Development Kit)

TypeScriptとの親和性が非常に高く、型安全にインフラを定義：

```typescript
import * as cdk from 'aws-cdk-lib'
import * as lambda from 'aws-cdk-lib/aws-lambda'
import * as apigateway from 'aws-cdk-lib/aws-apigateway'

export class MyStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props)

    const handler = new lambda.Function(this, 'MyHandler', {
      runtime: lambda.Runtime.NODEJS_20_X,
      code: lambda.Code.fromAsset('dist'),
      handler: 'index.handler',
      architecture: lambda.Architecture.ARM_64,
    })

    new apigateway.LambdaRestApi(this, 'MyApi', {
      handler,
    })
  }
}
```

### その他のIaCツール

- **AWS SAM (Serverless Application Model)**: シンプルなYAMLベースの定義
- **Serverless Framework**: マルチクラウド対応

---

## その他のベストプラクティス

- **構造化ログ**: 不要な `console.log` は避け、必要な情報のみ出力（Powertools Loggerを推奨）
- **冪等性**: 必要な場合は明示的に設計（重複実行でも同じ結果）
- **タイムアウト**: 処理内容に応じて適切に設定
- **型定義**: `aws-lambda` パッケージの型を使用
  - `APIGatewayProxyEvent`, `APIGatewayProxyResult`
  - `EventBridgeEvent`, `SQSEvent`, `SQSBatchResponse`

---

## オプション: サードパーティライブラリ

このガイドでは汎用的な実装パターン（生のTypeScript/Node.js + AWS SDK直接使用）を中心に紹介していますが、以下のライブラリを使用することで開発効率を向上できます。

**これらは選択肢の一つであり、必須ではありません。**プロジェクトの要件・チームの方針に応じて選択してください。

### middy - ミドルウェアフレームワーク

Lambda関数に対して、Express.jsライクなミドルウェアパターンを適用できるフレームワーク。

#### 基本的な使用方法

```typescript
import middy from '@middy/core'
import httpJsonBodyParser from '@middy/http-json-body-parser'
import httpErrorHandler from '@middy/http-error-handler'
import httpSecurityHeaders from '@middy/http-security-headers'
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda'

const baseHandler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  // ビジネスロジックのみに集中（パース・バリデーション・エラーハンドリングはミドルウェアが担当）
  const result = await useCase.execute(event.body)
  return { statusCode: 200, body: JSON.stringify(result) }
}

export const handler = middy()
  .use(httpJsonBodyParser())        // JSON パース
  .use(httpSecurityHeaders())       // セキュリティヘッダー
  .use(httpErrorHandler())          // エラーハンドリング
  .handler(baseHandler)
```

#### メリット
- ✅ 共通処理（パース、バリデーション、ログ等）を再利用可能
- ✅ ハンドラーのコードがシンプルになる
- ✅ カスタムミドルウェアの作成が容易

#### デメリット
- ❌ ライブラリへの依存が増える
- ❌ ミドルウェアの実行順序を理解する必要がある

**公式サイト**: [middy.js.org](https://middy.js.org/)

---

### zod - スキーマバリデーション

TypeScript-firstのスキーマバリデーションライブラリ。型安全なバリデーションが可能。

#### 基本的な使用方法

```typescript
import { z } from 'zod'

// スキーマ定義
const requestSchema = z.object({
  imageId: z.string().min(1, 'imageId must not be empty'),
  cpu: z.number().positive('cpu must be positive').optional(),
  tags: z.array(z.string()).optional(),
})

// バリデーション実行
try {
  const validatedData = requestSchema.parse(event.body)
  // validatedDataは型安全（RequestBody型として推論される）
} catch (error) {
  if (error instanceof z.ZodError) {
    // エラーメッセージを整形
    const errors = error.errors.map((e) => `${e.path.join('.')}: ${e.message}`)
    return createResponse(400, { errors })
  }
}

// 型抽出も可能
type RequestBody = z.infer<typeof requestSchema>
```

#### メリット
- ✅ TypeScriptの型を自動生成できる
- ✅ 詳細なエラーメッセージ
- ✅ 複雑なバリデーションルールを簡潔に記述

#### デメリット
- ❌ ライブラリへの依存が増える
- ❌ シンプルな検証では冗長になる場合がある

**公式サイト**: [zod.dev](https://zod.dev/)

---

### その他の選択肢

#### バリデーションライブラリ
- **Joi**: Node.js向けの老舗バリデーションライブラリ（zodの代替）
- **yup**: React Hook Formなどとの統合が容易
- **ajv**: JSON Schema準拠の高速バリデーション
- **class-validator**: クラスベースのバリデーション（NestJS等で使用）

#### ユーティリティ
- **@aws-lambda-powertools/parameters**: SSM Parameter Store / Secrets Managerからのパラメータ取得（キャッシング機能付き）
- **lambda-api**: API Gatewayのルーティングを簡素化

