/**
 * レイヤードアーキテクチャ実装例
 *
 * Handler → UseCase → Repository の3層構造で責務を分離。
 * テスト容易性と保守性を向上させるパターンの完全な実装例。
 *
 * 構成：
 * - Handler層: イベント受信、パース、バリデーション、レスポンス生成
 * - UseCase層: ビジネスロジック（ドメイン知識を含む処理）
 * - Repository層: データ永続化（DynamoDB、RDS等）
 */

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda'

// ===========================
// Domain層: エンティティと値オブジェクト
// ===========================

interface User {
  userId: string
  email: string
  name: string
  status: 'active' | 'inactive'
  createdAt: string
}

interface CreateUserInput {
  email: string
  name: string
}

// ===========================
// Repository層: データ永続化
// ===========================

interface UserRepository {
  save(input: CreateUserInput): Promise<User>
  findById(userId: string): Promise<User | null>
  findByEmail(email: string): Promise<User | null>
}

/**
 * DynamoDB実装（実際のプロジェクトではAWS SDKを使用）
 */
class DynamoDBUserRepository implements UserRepository {
  private tableName: string

  constructor(tableName: string) {
    this.tableName = tableName
  }

  async save(input: CreateUserInput): Promise<User> {
    // 実際のプロジェクトでは以下のようにDynamoDBに保存
    // await dynamodb.send(new PutCommand({
    //   TableName: this.tableName,
    //   Item: user
    // }))

    const user: User = {
      userId: `user-${Date.now()}`,
      email: input.email,
      name: input.name,
      status: 'active',
      createdAt: new Date().toISOString(),
    }

    console.log(`[Repository] Saving user to table ${this.tableName}:`, user)

    return user
  }

  async findById(userId: string): Promise<User | null> {
    // 実際のプロジェクトでは以下のようにDynamoDBから取得
    // const result = await dynamodb.send(new GetCommand({
    //   TableName: this.tableName,
    //   Key: { userId }
    // }))
    // return result.Item as User | null

    console.log(`[Repository] Finding user by ID: ${userId}`)
    return null // モック
  }

  async findByEmail(email: string): Promise<User | null> {
    // 実際のプロジェクトでは以下のようにDynamoDBから検索
    // const result = await dynamodb.send(new QueryCommand({
    //   TableName: this.tableName,
    //   IndexName: 'EmailIndex',
    //   KeyConditionExpression: 'email = :email',
    //   ExpressionAttributeValues: { ':email': email }
    // }))
    // return result.Items?.[0] as User | null

    console.log(`[Repository] Finding user by email: ${email}`)
    return null // モック
  }
}

// ===========================
// UseCase層: ビジネスロジック
// ===========================

class DomainError extends Error {
  constructor(message: string, public statusCode: number = 400) {
    super(message)
    this.name = 'DomainError'
  }
}

class CreateUserUseCase {
  constructor(private userRepository: UserRepository) {}

  async execute(input: CreateUserInput): Promise<User> {
    // 1. ビジネスルールの検証
    await this.validateBusinessRules(input)

    // 2. データ永続化
    const user = await this.userRepository.save(input)

    console.log(`[UseCase] User created successfully: ${user.userId}`)

    return user
  }

  private async validateBusinessRules(input: CreateUserInput): Promise<void> {
    // メールアドレスの形式検証
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(input.email)) {
      throw new DomainError('Invalid email format', 400)
    }

    // メールアドレスの重複チェック（ビジネスルール）
    const existingUser = await this.userRepository.findByEmail(input.email)
    if (existingUser) {
      throw new DomainError('Email already exists', 409) // Conflict
    }

    // 名前の長さ検証
    if (input.name.length < 2 || input.name.length > 50) {
      throw new DomainError('Name must be between 2 and 50 characters', 400)
    }

    console.log(`[UseCase] Business rules validated for email: ${input.email}`)
  }
}

// ===========================
// Handler層: イベント処理
// ===========================

type ValidationResult<T> =
  | { valid: true; data: T }
  | { valid: false; errors: string[] }

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

function validateCreateUserInput(body: any): ValidationResult<CreateUserInput> {
  const errors: string[] = []

  if (typeof body !== 'object' || body === null) {
    errors.push('Request body must be an object')
    return { valid: false, errors }
  }

  if (typeof body.email !== 'string' || body.email.length === 0) {
    errors.push('email must be a non-empty string')
  }

  if (typeof body.name !== 'string' || body.name.length === 0) {
    errors.push('name must be a non-empty string')
  }

  if (errors.length > 0) {
    return { valid: false, errors }
  }

  return {
    valid: true,
    data: {
      email: body.email,
      name: body.name,
    },
  }
}

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

function handleError(error: unknown): APIGatewayProxyResult {
  if (error instanceof DomainError) {
    // ドメインエラー: ユーザーに理由を返す
    console.warn(`[Handler] Domain error: ${error.message}`)
    return createResponse(error.statusCode, { message: error.message })
  }

  if (error instanceof Error) {
    if (error.message.includes('empty') || error.message.includes('Invalid JSON')) {
      return createResponse(400, { message: error.message })
    }
  }

  // システムエラー: 詳細を隠す
  console.error('[Handler] System error:', error)
  return createResponse(500, { message: 'Internal server error' })
}

// ===========================
// 依存性注入: handler外で初期化
// ===========================

const TABLE_NAME = process.env.TABLE_NAME || 'Users'
const userRepository = new DynamoDBUserRepository(TABLE_NAME)
const createUserUseCase = new CreateUserUseCase(userRepository)

// ===========================
// Lambda ハンドラー
// ===========================

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    console.log('[Handler] Received event:', JSON.stringify(event))

    // 1. JSONパース
    const body = parseJSON(event.body)

    // 2. バリデーション（基本的な型検証）
    const validationResult = validateCreateUserInput(body)
    if (!validationResult.valid) {
      return createResponse(400, { errors: validationResult.errors })
    }

    // 3. ビジネスロジック実行（UseCaseに委譲）
    const user = await createUserUseCase.execute(validationResult.data)

    // 4. レスポンス生成
    return createResponse(201, { user })
  } catch (error) {
    // 5. エラーハンドリング
    return handleError(error)
  }
}

// ===========================
// テスト容易性の実証
// ===========================

/**
 * UseCaseは独立してテスト可能
 *
 * テストコード例：
 * ```typescript
 * const mockRepository: UserRepository = {
 *   save: jest.fn().mockResolvedValue({ userId: '123', email: 'test@example.com', ... }),
 *   findById: jest.fn().mockResolvedValue(null),
 *   findByEmail: jest.fn().mockResolvedValue(null)
 * }
 *
 * const useCase = new CreateUserUseCase(mockRepository)
 * const result = await useCase.execute({ email: 'test@example.com', name: 'Test User' })
 *
 * expect(mockRepository.save).toHaveBeenCalledWith({ email: 'test@example.com', name: 'Test User' })
 * expect(result.userId).toBe('123')
 * ```
 */

// ===========================
// ローカルデバッグ用（tsx で実行可能）
// ===========================

if (process.argv[1] === new URL(import.meta.url).pathname) {
  const mockEvent: APIGatewayProxyEvent = {
    body: JSON.stringify({
      email: 'john.doe@example.com',
      name: 'John Doe',
    }),
    headers: { 'Content-Type': 'application/json' },
    multiValueHeaders: {},
    httpMethod: 'POST',
    isBase64Encoded: false,
    path: '/users',
    pathParameters: null,
    queryStringParameters: null,
    multiValueQueryStringParameters: null,
    stageVariables: null,
    requestContext: {} as any,
    resource: '',
  }

  console.log('=== Layered Architecture Example ===\n')

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
