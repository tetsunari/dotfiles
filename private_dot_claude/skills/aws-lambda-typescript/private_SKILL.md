---
name: aws-lambda-typescript
description: AWS Lambda (TypeScript) のベストプラクティスガイド。API Gateway、EventBridge、SQS等の実装パターン、DynamoDB操作、エラーハンドリング、Powertools活用、パフォーマンス最適化を含む包括的なガイド。
---

# AWS Lambda (TypeScript) ベストプラクティス

Lambda関数を実装・レビューする際のガイドラインです。

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

### ミドルウェア（middy）の活用

リクエストパース、バリデーション、エラーハンドリングなど共通処理はミドルウェアで分離：

```typescript
import middy from '@middy/core'
import httpJsonBodyParser from '@middy/http-json-body-parser'
import httpErrorHandler from '@middy/http-error-handler'
import httpSecurityHeaders from '@middy/http-security-headers'

const baseHandler = async (event: ParsedEvent): Promise<APIGatewayProxyResult> => {
  // ビジネスロジックのみに集中
  const result = await useCase.execute(event.body)
  return { statusCode: 200, body: JSON.stringify(result) }
}

export const handler = middy<APIGatewayProxyEvent, APIGatewayProxyResult>()
  .use(httpJsonBodyParser())        // JSON パース
  .use(httpSecurityHeaders())       // セキュリティヘッダー
  .use(httpErrorHandler())          // エラーハンドリング
  .handler(baseHandler)
```

### リクエストバリデーション

Zod などのスキーマバリデーションを使用：

```typescript
import { z } from 'zod'

const requestSchema = z.object({
  imageId: z.string().min(1),
  cpu: z.number().positive().optional(),
})

// middy の .before フックで検証
.before(async (request) => {
  requestSchema.parse(request.event.body)
})
```

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

## 参考リンク

- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/)
- [AWS Lambda Powertools for TypeScript](https://docs.powertools.aws.dev/lambda/typescript/)
- [AWS SDK for JavaScript v3](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/)
- [middy - The Node.js middleware framework for AWS Lambda](https://middy.js.org/)
