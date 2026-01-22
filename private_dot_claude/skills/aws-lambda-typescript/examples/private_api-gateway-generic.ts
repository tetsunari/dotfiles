/**
 * API Gateway 汎用実装例
 *
 * このファイルは、middy/zodなどのライブラリを使用せずに、
 * 生のTypeScript + AWS SDKでAPI Gateway Lambdaを実装する完全な例です。
 *
 * 含まれる機能：
 * - JSONパース（エラーハンドリング付き）
 * - リクエストバリデーション（型ガード）
 * - セキュリティヘッダーの付与
 * - エラーハンドリング戦略
 */

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda'

// ===========================
// 型定義
// ===========================

interface CreateOrderRequest {
  productId: string
  quantity: number
  customerId: string
}

interface Order {
  orderId: string
  productId: string
  quantity: number
  customerId: string
  status: 'pending' | 'completed'
  createdAt: string
}

// ===========================
// ヘルパー関数: JSONパース
// ===========================

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

// ===========================
// ヘルパー関数: バリデーション
// ===========================

type ValidationResult<T> =
  | { valid: true; data: T }
  | { valid: false; errors: string[] }

function validateCreateOrderRequest(body: any): ValidationResult<CreateOrderRequest> {
  const errors: string[] = []

  if (typeof body !== 'object' || body === null) {
    errors.push('Request body must be an object')
    return { valid: false, errors }
  }

  // productId の検証
  if (typeof body.productId !== 'string' || body.productId.length === 0) {
    errors.push('productId must be a non-empty string')
  }

  // quantity の検証
  if (typeof body.quantity !== 'number' || body.quantity <= 0 || !Number.isInteger(body.quantity)) {
    errors.push('quantity must be a positive integer')
  }

  // customerId の検証
  if (typeof body.customerId !== 'string' || body.customerId.length === 0) {
    errors.push('customerId must be a non-empty string')
  }

  if (errors.length > 0) {
    return { valid: false, errors }
  }

  return {
    valid: true,
    data: {
      productId: body.productId,
      quantity: body.quantity,
      customerId: body.customerId,
    },
  }
}

// ===========================
// ヘルパー関数: レスポンス生成
// ===========================

function createResponse(statusCode: number, body: unknown): APIGatewayProxyResult {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      // セキュリティヘッダー
      'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Content-Security-Policy': "default-src 'self'",
    },
    body: JSON.stringify(body),
  }
}

// ===========================
// ヘルパー関数: エラーハンドリング
// ===========================

function handleError(error: unknown): APIGatewayProxyResult {
  console.error('Error occurred:', error)

  // ユーザー向けエラーの場合
  if (error instanceof Error) {
    if (error.message.includes('empty') || error.message.includes('Invalid JSON')) {
      return createResponse(400, { message: error.message })
    }
  }

  // システムエラー（詳細を隠す）
  return createResponse(500, { message: 'Internal server error' })
}

// ===========================
// ビジネスロジック
// ===========================

async function createOrder(request: CreateOrderRequest): Promise<Order> {
  // 実際のプロジェクトでは、ここでDynamoDB等に保存
  // この例ではモックデータを返す
  const orderId = `order-${Date.now()}`

  const order: Order = {
    orderId,
    productId: request.productId,
    quantity: request.quantity,
    customerId: request.customerId,
    status: 'pending',
    createdAt: new Date().toISOString(),
  }

  console.log('Order created:', order)

  return order
}

// ===========================
// Lambda ハンドラー
// ===========================

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // 1. JSONパース（エラーハンドリング付き）
    const body = parseJSON(event.body)

    // 2. バリデーション
    const validationResult = validateCreateOrderRequest(body)
    if (!validationResult.valid) {
      return createResponse(400, { errors: validationResult.errors })
    }

    // 3. ビジネスロジック実行
    const order = await createOrder(validationResult.data)

    // 4. レスポンス生成（セキュリティヘッダー付き）
    return createResponse(201, { order })
  } catch (error) {
    // 5. エラーハンドリング
    return handleError(error)
  }
}

// ===========================
// ローカルデバッグ用（tsx で実行可能）
// ===========================

if (process.argv[1] === new URL(import.meta.url).pathname) {
  const mockEvent: APIGatewayProxyEvent = {
    body: JSON.stringify({
      productId: 'prod-123',
      quantity: 2,
      customerId: 'cust-456',
    }),
    headers: { 'Content-Type': 'application/json' },
    multiValueHeaders: {},
    httpMethod: 'POST',
    isBase64Encoded: false,
    path: '/orders',
    pathParameters: null,
    queryStringParameters: null,
    multiValueQueryStringParameters: null,
    stageVariables: null,
    requestContext: {} as any,
    resource: '',
  }

  handler(mockEvent, {} as any, {} as any)
    .then((result) => {
      console.log('\n✅ Success:')
      console.log(JSON.stringify(result, null, 2))
    })
    .catch((error) => {
      console.error('\n❌ Error:')
      console.error(error)
    })
}
