# Security Patterns: Code Examples

`security-review/SKILL.md` から切り出した詳細コード実装例。

## 1. Secrets Management

### ❌ NEVER Do This
```typescript
const apiKey = "sk-proj-xxxxx"  // Hardcoded secret
const dbPassword = "password123" // In source code
```

### ✅ ALWAYS Do This
```typescript
const apiKey = process.env.OPENAI_API_KEY
const dbUrl = process.env.DATABASE_URL

if (!apiKey) {
  throw new Error('OPENAI_API_KEY not configured')
}
```

## 2. Input Validation

### Always Validate User Input
```typescript
import { z } from 'zod'

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150)
})

export async function createUser(input: unknown) {
  try {
    const validated = CreateUserSchema.parse(input)
    return await db.users.create(validated)
  } catch (error) {
    if (error instanceof z.ZodError) {
      return { success: false, errors: error.errors }
    }
    throw error
  }
}
```

### File Upload Validation
```typescript
function validateFileUpload(file: File) {
  const maxSize = 5 * 1024 * 1024
  if (file.size > maxSize) throw new Error('File too large (max 5MB)')

  const allowedTypes = ['image/jpeg', 'image/png', 'image/gif']
  if (!allowedTypes.includes(file.type)) throw new Error('Invalid file type')

  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif']
  const extension = file.name.toLowerCase().match(/\.[^.]+$/)?.[0]
  if (!extension || !allowedExtensions.includes(extension)) {
    throw new Error('Invalid file extension')
  }

  return true
}
```

## 3. SQL Injection Prevention

```typescript
// ❌ DANGEROUS
const query = `SELECT * FROM users WHERE email = '${userEmail}'`

// ✅ Parameterized query
const { data } = await supabase
  .from('users')
  .select('*')
  .eq('email', userEmail)

// ✅ Raw SQL with parameters
await db.query('SELECT * FROM users WHERE email = $1', [userEmail])
```

## 4. Authentication & Authorization

### JWT Token Handling
```typescript
// ❌ WRONG: localStorage (vulnerable to XSS)
localStorage.setItem('token', token)

// ✅ CORRECT: httpOnly cookies
res.setHeader('Set-Cookie',
  `token=${token}; HttpOnly; Secure; SameSite=Strict; Max-Age=3600`)
```

### Authorization Checks
```typescript
export async function deleteUser(userId: string, requesterId: string) {
  const requester = await db.users.findUnique({ where: { id: requesterId } })

  if (requester.role !== 'admin') {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })
  }

  await db.users.delete({ where: { id: userId } })
}
```

### Row Level Security (Supabase)
```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own data"
  ON users FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users update own data"
  ON users FOR UPDATE USING (auth.uid() = id);
```

## 5. XSS Prevention

```typescript
import DOMPurify from 'isomorphic-dompurify'

function renderUserContent(html: string) {
  const clean = DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'p'],
    ALLOWED_ATTR: []
  })
  return <div dangerouslySetInnerHTML={{ __html: clean }} />
}
```

### Content Security Policy
```typescript
// next.config.js
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: `
      default-src 'self';
      script-src 'self' 'unsafe-eval' 'unsafe-inline';
      style-src 'self' 'unsafe-inline';
      img-src 'self' data: https:;
      connect-src 'self' https://api.example.com;
    `.replace(/\s{2,}/g, ' ').trim()
  }
]
```

## 6. CSRF Protection

```typescript
import { csrf } from '@/lib/csrf'

export async function POST(request: Request) {
  const token = request.headers.get('X-CSRF-Token')
  if (!csrf.verify(token)) {
    return NextResponse.json({ error: 'Invalid CSRF token' }, { status: 403 })
  }
}

// SameSite Cookie
res.setHeader('Set-Cookie',
  `session=${sessionId}; HttpOnly; Secure; SameSite=Strict`)
```

## 7. Rate Limiting

```typescript
import rateLimit from 'express-rate-limit'

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Too many requests'
})

app.use('/api/', limiter)

// Stricter for expensive ops
const searchLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: 'Too many search requests'
})

app.use('/api/search', searchLimiter)
```

## 8. Sensitive Data Exposure

```typescript
// ❌ WRONG
console.log('User login:', { email, password })

// ✅ CORRECT
console.log('User login:', { email, userId })

// ❌ WRONG: Exposing internals
catch (error) {
  return NextResponse.json({ error: error.message, stack: error.stack }, { status: 500 })
}

// ✅ CORRECT
catch (error) {
  console.error('Internal error:', error)
  return NextResponse.json({ error: 'An error occurred. Please try again.' }, { status: 500 })
}
```

## 9. Blockchain Security (Solana)

```typescript
import { verify } from '@solana/web3.js'

async function verifyWalletOwnership(publicKey: string, signature: string, message: string) {
  try {
    return verify(
      Buffer.from(message),
      Buffer.from(signature, 'base64'),
      Buffer.from(publicKey, 'base64')
    )
  } catch {
    return false
  }
}

async function verifyTransaction(transaction: Transaction) {
  if (transaction.to !== expectedRecipient) throw new Error('Invalid recipient')
  if (transaction.amount > maxAmount) throw new Error('Amount exceeds limit')
  const balance = await getBalance(transaction.from)
  if (balance < transaction.amount) throw new Error('Insufficient balance')
  return true
}
```

## 10. Dependency Security

```bash
npm audit
npm audit fix
npm update
npm outdated
git add package-lock.json
npm ci
```

## Security Testing

```typescript
test('requires authentication', async () => {
  const response = await fetch('/api/protected')
  expect(response.status).toBe(401)
})

test('requires admin role', async () => {
  const response = await fetch('/api/admin', {
    headers: { Authorization: `Bearer ${userToken}` }
  })
  expect(response.status).toBe(403)
})

test('rejects invalid input', async () => {
  const response = await fetch('/api/users', {
    method: 'POST',
    body: JSON.stringify({ email: 'not-an-email' })
  })
  expect(response.status).toBe(400)
})

test('enforces rate limits', async () => {
  const requests = Array(101).fill(null).map(() => fetch('/api/endpoint'))
  const responses = await Promise.all(requests)
  const tooManyRequests = responses.filter(r => r.status === 429)
  expect(tooManyRequests.length).toBeGreaterThan(0)
})
```
