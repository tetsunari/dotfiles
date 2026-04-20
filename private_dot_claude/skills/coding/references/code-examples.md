# Code Examples

`coding/SKILL.md` から切り出した詳細コード実装例。

## TypeScript/JavaScript Standards

### Variable Naming

```typescript
// ✅ GOOD: Descriptive names
const marketSearchQuery = 'election'
const isUserAuthenticated = true
const totalRevenue = 1000

// ❌ BAD: Unclear names
const q = 'election'
const flag = true
const x = 1000
```

### Function Naming

```typescript
// ✅ GOOD: Verb-noun pattern
async function fetchMarketData(marketId: string) { }
function calculateSimilarity(a: number[], b: number[]) { }
function isValidEmail(email: string): boolean { }

// ❌ BAD: Unclear or noun-only
async function market(id: string) { }
function similarity(a, b) { }
```

### Async/Await Best Practices

```typescript
// ✅ GOOD: Parallel execution
const [users, markets, stats] = await Promise.all([
  fetchUsers(),
  fetchMarkets(),
  fetchStats()
])

// ❌ BAD: Sequential when unnecessary
const users = await fetchUsers()
const markets = await fetchMarkets()
const stats = await fetchStats()
```

### Type Safety

```typescript
// ✅ GOOD: Proper types
interface Market {
  id: string
  name: string
  status: 'active' | 'resolved' | 'closed'
  created_at: Date
}

function getMarket(id: string): Promise<Market> { }

// ❌ BAD: Using 'any'
function getMarket(id: any): Promise<any> { }
```

## React Best Practices

### Component Structure

```typescript
interface ButtonProps {
  children: React.ReactNode
  onClick: () => void
  disabled?: boolean
  variant?: 'primary' | 'secondary'
}

export function Button({
  children,
  onClick,
  disabled = false,
  variant = 'primary'
}: ButtonProps) {
  return (
    <button onClick={onClick} disabled={disabled} className={`btn btn-${variant}`}>
      {children}
    </button>
  )
}

// ❌ BAD: No types, unclear structure
export function Button(props) {
  return <button onClick={props.onClick}>{props.children}</button>
}
```

### State Management

```typescript
// ✅ GOOD: Functional update
setCount(prev => prev + 1)

// ❌ BAD: Direct state reference (can be stale in async scenarios)
setCount(count + 1)
```

### Conditional Rendering

```typescript
// ✅ GOOD
{isLoading && <Spinner />}
{error && <ErrorMessage error={error} />}
{data && <DataDisplay data={data} />}

// ❌ BAD: Ternary hell
{isLoading ? <Spinner /> : error ? <ErrorMessage error={error} /> : data ? <DataDisplay data={data} /> : null}
```

## API Design Standards

### REST Conventions

```
GET    /api/markets              # List all
GET    /api/markets/:id          # Get specific
POST   /api/markets              # Create
PUT    /api/markets/:id          # Update (full)
PATCH  /api/markets/:id          # Update (partial)
DELETE /api/markets/:id          # Delete

GET /api/markets?status=active&limit=10&offset=0
```

## Performance Best Practices

### Memoization

```typescript
const sortedMarkets = useMemo(() => {
  return markets.sort((a, b) => b.volume - a.volume)
}, [markets])

const handleSearch = useCallback((query: string) => {
  setSearchQuery(query)
}, [])
```

### Lazy Loading

```typescript
const HeavyChart = lazy(() => import('./HeavyChart'))

export function Dashboard() {
  return (
    <Suspense fallback={<Spinner />}>
      <HeavyChart />
    </Suspense>
  )
}
```

### Database Queries

```typescript
// ✅ GOOD: Select only needed columns
const { data } = await supabase
  .from('markets')
  .select('id, name, status')
  .limit(10)

// ❌ BAD: Select everything
const { data } = await supabase.from('markets').select('*')
```

## Testing Standards

### AAA Pattern

```typescript
test('calculates similarity correctly', () => {
  // Arrange
  const vector1 = [1, 0, 0]
  const vector2 = [0, 1, 0]

  // Act
  const similarity = calculateCosineSimilarity(vector1, vector2)

  // Assert
  expect(similarity).toBe(0)
})
```

### Test Naming

```typescript
// ✅ GOOD: Descriptive
test('returns empty array when no markets match query', () => { })
test('throws error when OpenAI API key is missing', () => { })

// ❌ BAD: Vague
test('works', () => { })
test('test search', () => { })
```

### JSDoc for Public APIs

```typescript
/**
 * Searches markets using semantic similarity.
 * @param query - Natural language search query
 * @param limit - Maximum number of results (default: 10)
 * @returns Array of markets sorted by similarity score
 * @throws {Error} If OpenAI API fails or Redis unavailable
 */
export async function searchMarkets(query: string, limit: number = 10): Promise<Market[]> { }
```

## Code Smell Detection

### Long Functions

```typescript
// ❌ BAD: Function > 50 lines
function processMarketData() { /* 100 lines */ }

// ✅ GOOD: Split
function processMarketData() {
  const validated = validateData()
  const transformed = transformData(validated)
  return saveData(transformed)
}
```

### Deep Nesting

```typescript
// ❌ BAD: 5+ levels
if (user) {
  if (user.isAdmin) {
    if (market) {
      if (market.isActive) {
        if (hasPermission) { /* Do something */ }
      }
    }
  }
}

// ✅ GOOD: Early returns
if (!user) return
if (!user.isAdmin) return
if (!market) return
if (!market.isActive) return
if (!hasPermission) return
// Do something
```

### Magic Numbers

```typescript
// ❌ BAD
if (retryCount > 3) { }
setTimeout(callback, 500)

// ✅ GOOD
const MAX_RETRIES = 3
const DEBOUNCE_DELAY_MS = 500

if (retryCount > MAX_RETRIES) { }
setTimeout(callback, DEBOUNCE_DELAY_MS)
```
