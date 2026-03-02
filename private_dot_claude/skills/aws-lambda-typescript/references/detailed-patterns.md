# AWS Lambda (TypeScript) 詳細パターン集

> Reference for skill: **aws-lambda-typescript**

## API Gateway 経由の Lambda

### 汎用実装パターン（生のTypeScript）

リクエストパース、バリデーション、エラーハンドリングなどを明示的に実装：

```typescript
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda'

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const body = parseJSON(event.body)
    const validationResult = validateRequest(body)
    if (!validationResult.valid) {
      return createResponse(400, { errors: validationResult.errors })
    }
    const result = await executeBusinessLogic(validationResult.data)
    return createResponse(200, result)
  } catch (error) {
    return handleError(error)
  }
}

function parseJSON(body: string | null): unknown {
  if (!body) throw new Error('Request body is empty')
  try {
    return JSON.parse(body)
  } catch (error) {
    throw new Error('Invalid JSON format')
  }
}

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

function handleError(error: unknown): APIGatewayProxyResult {
  console.error('Error:', error)
  const message = error instanceof Error ? error.message : 'Internal server error'
  return createResponse(500, { message })
}
```

### リクエストバリデーション

```typescript
interface RequestBody {
  imageId: string
  cpu?: number
}

function isValidRequestBody(body: any): body is RequestBody {
  return (
    typeof body === 'object' &&
    body !== null &&
    typeof body.imageId === 'string' &&
    body.imageId.length > 0 &&
    (body.cpu === undefined || (typeof body.cpu === 'number' && body.cpu > 0))
  )
}

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
  if (errors.length > 0) return { valid: false, errors }
  return { valid: true, data: body as RequestBody }
}
```

### パスパラメータの取得

```typescript
const sessionId = event.pathParameters?.id
if (!sessionId) {
  return { statusCode: 400, body: JSON.stringify({ message: 'sessionId is required' }) }
}
```

### レスポンスヘルパー

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

自前のページネーションループは書かない。SDK v3 の `paginateScan` / `paginateQuery` を使用：

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

- 大量データでなければシンプルなループを優先
- `BatchWriteItem` の `UnprocessedItems` 処理は複雑なので、要件上必須でなければ `PutItem` / `DeleteItem` のループでOK

### 楽観的ロック（条件付き更新）

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

Lambda実行が終了する前に全ての非同期処理が完了していることを保証する必要があります：

```typescript
// 注意: レスポンス返却後も非同期で監視（完了を待たない）
checkStatusAsync(commandId)
  .then((output) => console.log('Command completed:', output))
  .catch((error) => console.error('Command failed:', getErrorMessage(error)))

return { statusCode: 202, body: JSON.stringify({ id: commandId }) }
```

### Promise.all による完了保証

```typescript
const [result1, result2] = await Promise.all([
  operation1(),
  operation2(),
])

return { statusCode: 200, body: JSON.stringify({ result1, result2 }) }
```

---

## ロールバック・補償処理

```typescript
let resourceAllocated = false
try {
  await allocateResource()
  resourceAllocated = true
  await saveToDatabase()
} catch (error) {
  if (resourceAllocated) {
    await releaseResource().catch((e) => {
      console.warn('Rollback failed:', getErrorMessage(e))
    })
  }
  throw error
}
```

複雑な分散トランザクションには **AWS Step Functions の Saga パターン** を検討。

---

## AWS Lambda Powertools for TypeScript

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

```typescript
import { getParameter } from '@aws-lambda-powertools/parameters/ssm'

const dbPassword = await getParameter('/myapp/database/password', {
  maxAge: 300,
  transform: 'json',
})
```

### Idempotency（冪等性）

```typescript
import { makeIdempotent } from '@aws-lambda-powertools/idempotency'
import { DynamoDBPersistenceLayer } from '@aws-lambda-powertools/idempotency/dynamodb'

const persistenceStore = new DynamoDBPersistenceLayer({
  tableName: 'IdempotencyTable',
})

const handler = async (event) => {
  return { statusCode: 200, body: 'Success' }
}

export const lambdaHandler = makeIdempotent(handler, {
  persistenceStore,
  config: {
    eventKeyJmesPath: 'body.requestId',
  },
})
```

---

## Lambda SnapStart for Node.js

コールドスタートを最大90%削減。

### 有効化方法（AWS CDK）

```typescript
new lambda.Function(this, 'MyFunction', {
  runtime: lambda.Runtime.NODEJS_20_X,
  snapStart: lambda.SnapStartConf.ON_PUBLISHED_VERSIONS,
})
```

### 注意事項

初期化時に生成されるユニークなIDやネットワーク接続は、リストア後には古くなっている可能性があります：

```typescript
import { SnapStart } from '@aws-lambda-powertools/commons'

SnapStart.beforeCheckpoint(async () => {
  console.log('Creating snapshot...')
})

SnapStart.afterRestore(async () => {
  console.log('Restoring from snapshot...')
})
```

---

## ECMAScript Modules (ESM)

### 有効化

`package.json` に `"type": "module"` を追加。

### Top-level await

```typescript
const config = await fetchConfig()

export const handler = async (event) => {
  // ...
}
```

### 注意事項

- `require()` は使えません（`import` を使用）
- `__dirname` と `__filename` は使えません：

```typescript
import { fileURLToPath } from 'node:url'
import { dirname } from 'node:path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)
```

---

## コストとパフォーマンスの最適化

### Graviton2 (arm64) アーキテクチャ

```typescript
new lambda.Function(this, 'MyFunction', {
  runtime: lambda.Runtime.NODEJS_20_X,
  architecture: lambda.Architecture.ARM_64,
})
```

### Lambda Power Tuning

最適なメモリサイズを見つけるツール：[AWS Lambda Power Tuning](https://github.com/alexcasalboni/aws-lambda-power-tuning)

---

## セキュリティの強化

### 最小権限の原則

```typescript
new iam.PolicyStatement({
  actions: ['dynamodb:GetItem', 'dynamodb:PutItem'],
  resources: ['arn:aws:dynamodb:region:account:table/MyTable'],
})
```

### シークレット管理

```typescript
import { getSecret } from '@aws-lambda-powertools/parameters/secrets'

const dbCredentials = await getSecret('myapp/database/credentials', {
  transform: 'json',
})
```

---

## ローカルデバッグ

| フェーズ | 目的 | 推奨ツール |
|---------|------|-----------|
| ユニットテスト | ビジネスロジックの単体検証 | vitest / jest |
| ローカル手動実行 | 開発初期の動作確認 | tsx |
| ローカル統合テスト | Lambda実行環境含めたテスト | AWS SAM CLI |
| クラウド連携デバッグ | IAM権限や他サービス連携 | SST Live Lambda Development |

### tsx による手動実行

```bash
npx tsx src/lambda/handlers/create-session.ts
```

```typescript
import { fileURLToPath } from 'node:url'

export const handler = async (event: APIGatewayProxyEvent) => {
  // ハンドラー実装
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const mockEvent = {
    body: JSON.stringify({ imageId: 'test-image', cpu: 2 }),
    headers: { 'Content-Type': 'application/json' },
    httpMethod: 'POST',
    // ...
  } as APIGatewayProxyEvent

  handler(mockEvent)
    .then((result) => console.log('Success:', JSON.stringify(result, null, 2)))
    .catch((error) => console.error('Error:', error))
}
```

### AWS SAM CLI

```bash
sam local invoke MyFunction -e events/test-event.json
sam local start-api
```

### SST Live Lambda Development

コードをローカルで実行しつつ、リクエストは実際のAWS環境から受け取る。詳細: [sst.dev](https://sst.dev/)

---

## IaC（Infrastructure as Code）

### AWS CDK

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
    new apigateway.LambdaRestApi(this, 'MyApi', { handler })
  }
}
```

### その他のIaCツール

- **AWS SAM**: シンプルなYAMLベースの定義
- **Serverless Framework**: マルチクラウド対応

---

## オプション: サードパーティライブラリ

### middy - ミドルウェアフレームワーク

```typescript
import middy from '@middy/core'
import httpJsonBodyParser from '@middy/http-json-body-parser'
import httpErrorHandler from '@middy/http-error-handler'
import httpSecurityHeaders from '@middy/http-security-headers'

const baseHandler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const result = await useCase.execute(event.body)
  return { statusCode: 200, body: JSON.stringify(result) }
}

export const handler = middy()
  .use(httpJsonBodyParser())
  .use(httpSecurityHeaders())
  .use(httpErrorHandler())
  .handler(baseHandler)
```

公式サイト: [middy.js.org](https://middy.js.org/)

### zod - スキーマバリデーション

```typescript
import { z } from 'zod'

const requestSchema = z.object({
  imageId: z.string().min(1, 'imageId must not be empty'),
  cpu: z.number().positive('cpu must be positive').optional(),
  tags: z.array(z.string()).optional(),
})

try {
  const validatedData = requestSchema.parse(event.body)
} catch (error) {
  if (error instanceof z.ZodError) {
    const errors = error.errors.map((e) => `${e.path.join('.')}: ${e.message}`)
    return createResponse(400, { errors })
  }
}

type RequestBody = z.infer<typeof requestSchema>
```

公式サイト: [zod.dev](https://zod.dev/)

### その他の選択肢

- **Joi / yup / ajv / class-validator**: バリデーションライブラリ
- **@aws-lambda-powertools/parameters**: SSM/Secrets Manager（キャッシング付き）
- **lambda-api**: API Gatewayのルーティング簡素化
