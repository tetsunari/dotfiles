/**
 * エラーハンドリング戦略の実装例
 *
 * ドメインエラーとシステムエラーを適切に分類し、
 * 適切なHTTPステータスコードとメッセージを返す完全な例。
 *
 * エラー分類：
 * - ドメインエラー: ビジネスルール違反（400, 403, 404, 409等）
 * - システムエラー: インフラ障害、予期しないエラー（500）
 */

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda'

// ===========================
// カスタムエラークラス
// ===========================

/**
 * ドメインエラー: ビジネスルール違反
 * ユーザーに理由を返しても問題ない
 */
class DomainError extends Error {
  constructor(message: string, public readonly statusCode: number = 400, public readonly errorCode?: string) {
    super(message)
    this.name = 'DomainError'
    Object.setPrototypeOf(this, DomainError.prototype)
  }
}

/**
 * バリデーションエラー: 入力データの形式エラー
 */
class ValidationError extends DomainError {
  constructor(message: string, public readonly field?: string) {
    super(message, 400, 'VALIDATION_ERROR')
    this.name = 'ValidationError'
    Object.setPrototypeOf(this, ValidationError.prototype)
  }
}

/**
 * 認証エラー: ユーザー認証失敗
 */
class AuthenticationError extends DomainError {
  constructor(message: string = 'Authentication required') {
    super(message, 401, 'AUTHENTICATION_ERROR')
    this.name = 'AuthenticationError'
    Object.setPrototypeOf(this, AuthenticationError.prototype)
  }
}

/**
 * 認可エラー: 権限不足
 */
class AuthorizationError extends DomainError {
  constructor(message: string = 'Insufficient permissions') {
    super(message, 403, 'AUTHORIZATION_ERROR')
    this.name = 'AuthorizationError'
    Object.setPrototypeOf(this, AuthorizationError.prototype)
  }
}

/**
 * リソース未発見エラー
 */
class NotFoundError extends DomainError {
  constructor(resource: string, id: string) {
    super(`${resource} not found: ${id}`, 404, 'NOT_FOUND')
    this.name = 'NotFoundError'
    Object.setPrototypeOf(this, NotFoundError.prototype)
  }
}

/**
 * リソース競合エラー（既に存在する等）
 */
class ConflictError extends DomainError {
  constructor(message: string) {
    super(message, 409, 'CONFLICT')
    this.name = 'ConflictError'
    Object.setPrototypeOf(this, ConflictError.prototype)
  }
}

// ===========================
// エラーレスポンス型定義
// ===========================

interface ErrorResponse {
  error: {
    message: string
    code?: string
    field?: string
    details?: unknown
  }
}

// ===========================
// エラーハンドリング関数
// ===========================

function createResponse(statusCode: number, body: unknown): APIGatewayProxyResult {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'X-Content-Type-Options': 'nosniff',
    },
    body: JSON.stringify(body),
  }
}

/**
 * 統合エラーハンドラー
 * エラーの種類に応じて適切なレスポンスを返す
 */
function handleError(error: unknown): APIGatewayProxyResult {
  // 1. ドメインエラー（ビジネスルール違反）
  if (error instanceof DomainError) {
    console.warn(`[Domain Error] ${error.name}: ${error.message}`, {
      statusCode: error.statusCode,
      errorCode: error.errorCode,
    })

    const response: ErrorResponse = {
      error: {
        message: error.message,
        code: error.errorCode,
      },
    }

    // バリデーションエラーの場合はフィールド情報も含める
    if (error instanceof ValidationError && error.field) {
      response.error.field = error.field
    }

    return createResponse(error.statusCode, response)
  }

  // 2. 標準Errorオブジェクト（システムエラーの可能性）
  if (error instanceof Error) {
    console.error(`[System Error] ${error.name}: ${error.message}`, {
      stack: error.stack,
    })

    // セキュリティ上、詳細を隠す
    return createResponse(500, {
      error: {
        message: 'Internal server error',
        code: 'INTERNAL_ERROR',
      },
    })
  }

  // 3. 予期しないエラー型
  console.error('[Unknown Error]', error)
  return createResponse(500, {
    error: {
      message: 'Internal server error',
      code: 'INTERNAL_ERROR',
    },
  })
}

// ===========================
// ビジネスロジック例
// ===========================

interface Product {
  productId: string
  name: string
  price: number
  stock: number
}

interface PurchaseRequest {
  productId: string
  quantity: number
  userId: string
}

class ProductService {
  private products: Map<string, Product> = new Map([
    ['prod-1', { productId: 'prod-1', name: 'Laptop', price: 1000, stock: 5 }],
    ['prod-2', { productId: 'prod-2', name: 'Mouse', price: 20, stock: 0 }],
  ])

  async purchaseProduct(request: PurchaseRequest): Promise<{ success: boolean; orderId: string }> {
    // 1. バリデーション
    if (request.quantity <= 0) {
      throw new ValidationError('Quantity must be positive', 'quantity')
    }

    // 2. 商品の存在確認
    const product = this.products.get(request.productId)
    if (!product) {
      throw new NotFoundError('Product', request.productId)
    }

    // 3. 在庫確認（ビジネスルール）
    if (product.stock < request.quantity) {
      throw new ConflictError(`Insufficient stock. Available: ${product.stock}, Requested: ${request.quantity}`)
    }

    // 4. 認可チェック（例）
    if (request.userId === 'banned-user') {
      throw new AuthorizationError('User is banned from purchasing')
    }

    // 5. 在庫を減らして注文を作成
    product.stock -= request.quantity
    const orderId = `order-${Date.now()}`

    console.log(`[Service] Purchase successful: ${orderId}`, { product: product.name, quantity: request.quantity })

    return { success: true, orderId }
  }
}

// ===========================
// Lambda ハンドラー
// ===========================

const productService = new ProductService()

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    console.log('[Handler] Processing purchase request')

    // リクエストパース
    if (!event.body) {
      throw new ValidationError('Request body is required')
    }

    const request: PurchaseRequest = JSON.parse(event.body)

    // 認証チェック（例）
    const authHeader = event.headers['Authorization'] || event.headers['authorization']
    if (!authHeader) {
      throw new AuthenticationError()
    }

    // ビジネスロジック実行
    const result = await productService.purchaseProduct(request)

    return createResponse(200, { data: result })
  } catch (error) {
    // エラーハンドリング（統合ハンドラーに委譲）
    return handleError(error)
  }
}

// ===========================
// ローカルデバッグ用（tsx で実行可能）
// ===========================

if (process.argv[1] === new URL(import.meta.url).pathname) {
  console.log('=== Error Handling Strategy Example ===\n')

  // テストケース1: 正常系
  console.log('--- Test Case 1: Success ---')
  const successEvent: APIGatewayProxyEvent = {
    body: JSON.stringify({
      productId: 'prod-1',
      quantity: 2,
      userId: 'user-123',
    }),
    headers: { Authorization: 'Bearer token123' },
    multiValueHeaders: {},
    httpMethod: 'POST',
    isBase64Encoded: false,
    path: '/purchase',
    pathParameters: null,
    queryStringParameters: null,
    multiValueQueryStringParameters: null,
    stageVariables: null,
    requestContext: {} as any,
    resource: '',
  }

  handler(successEvent, {} as any, {} as any)
    .then((result) => {
      console.log('Response:', JSON.stringify(result, null, 2))
    })
    .catch(console.error)

  // テストケース2: 認証エラー
  console.log('\n--- Test Case 2: Authentication Error ---')
  const authErrorEvent: APIGatewayProxyEvent = {
    ...successEvent,
    headers: {}, // Authorizationヘッダーなし
  }

  handler(authErrorEvent, {} as any, {} as any)
    .then((result) => {
      console.log('Response:', JSON.stringify(result, null, 2))
    })
    .catch(console.error)

  // テストケース3: 商品未発見エラー
  console.log('\n--- Test Case 3: Not Found Error ---')
  const notFoundEvent: APIGatewayProxyEvent = {
    ...successEvent,
    body: JSON.stringify({
      productId: 'prod-999', // 存在しない商品
      quantity: 1,
      userId: 'user-123',
    }),
  }

  handler(notFoundEvent, {} as any, {} as any)
    .then((result) => {
      console.log('Response:', JSON.stringify(result, null, 2))
    })
    .catch(console.error)

  // テストケース4: 在庫不足エラー
  console.log('\n--- Test Case 4: Insufficient Stock Error ---')
  const stockErrorEvent: APIGatewayProxyEvent = {
    ...successEvent,
    body: JSON.stringify({
      productId: 'prod-2', // 在庫0の商品
      quantity: 1,
      userId: 'user-123',
    }),
  }

  handler(stockErrorEvent, {} as any, {} as any)
    .then((result) => {
      console.log('Response:', JSON.stringify(result, null, 2))
    })
    .catch(console.error)

  // テストケース5: バリデーションエラー
  console.log('\n--- Test Case 5: Validation Error ---')
  const validationErrorEvent: APIGatewayProxyEvent = {
    ...successEvent,
    body: JSON.stringify({
      productId: 'prod-1',
      quantity: -5, // 不正な値
      userId: 'user-123',
    }),
  }

  handler(validationErrorEvent, {} as any, {} as any)
    .then((result) => {
      console.log('Response:', JSON.stringify(result, null, 2))
    })
    .catch(console.error)
}
