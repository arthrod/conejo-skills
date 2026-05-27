# Coding Standards & Best Practices

Universal coding standards applicable across all projects.

## When to Activate

- Reviewing code for quality and maintainability
- Refactoring existing code to follow conventions
- Enforcing naming, formatting, or structural consistency
- Setting up linting, formatting, or type-checking rules

## Framework-Specific Patterns

If the task involves a specific framework, use the dedicated skill instead of this file:

| Framework | Skill | Covers |
|-----------|-------|--------|
| React | `skill: react-patterns` | Components, Hooks, Zustand, performance, anti-patterns |

This skill focuses on **framework-agnostic** standards: naming, types, error handling, file organization, API design.

## Reference Files

| Topic | File | When to read |
|-------|------|-------------|
| API Design | `references/coding-standards-api-design.md` | Designing REST APIs, response formats, validation |
| Testing | `references/coding-standards-testing.md` | Code smells and test structure — see also `references/testing-doctrine.md` |

## Code Quality Principles

### 1. Readability First
- Code is read more than written
- Clear variable and function names
- Self-documenting code preferred over comments
- Consistent formatting

### 2. KISS (Keep It Simple, Stupid)
- Simplest solution that works
- Avoid over-engineering
- No premature optimization
- Easy to understand > clever code

### 3. DRY (Don't Repeat Yourself)
- Extract common logic into functions
- Create reusable components
- Share utilities across modules
- Avoid copy-paste programming

### 4. YAGNI (You Aren't Gonna Need It)
- Don't build features before they're needed
- Avoid speculative generality
- Add complexity only when required
- Start simple, refactor when needed

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
function email(e) { }
```

### Immutability Pattern

```typescript
// ✅ ALWAYS use spread operator
const updatedUser = { ...user, name: 'New Name' }
const updatedArray = [...items, newItem]

// ❌ NEVER mutate directly
user.name = 'New Name'  // BAD
items.push(newItem)     // BAD
```

### Error Handling

```typescript
// ✅ GOOD: Comprehensive error handling
async function fetchData(url: string) {
  try {
    const response = await fetch(url)
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
    return await response.json()
  } catch (error) {
    console.error('Fetch failed:', error)
    throw new Error('Failed to fetch data')
  }
}
```

### Async/Await Best Practices

```typescript
// ✅ GOOD: Parallel execution when possible
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

### ESM — No CommonJS

This project uses ESM only. Always use `import`/`export`; never use CommonJS (`require` / `exports` patterns).

```typescript
// ✅ GOOD: ESM imports/exports
import { fetchMarkets } from './market-service.js'
export function calculateScore(value: number) { }
```

## File Organization

### Project Structure

```
src/
├── lib/                  # Utilities and configs
├── types/                # TypeScript types
└── scripts/              # CLI entry points
```

### File Naming

```
lib/format-date.ts        # kebab-case for utilities
types/market.types.ts     # kebab-case with .types suffix
scripts/validate.ts       # kebab-case for CLIs
```

## Comments & Documentation

```typescript
// ✅ GOOD: Explain WHY, not WHAT
// Use exponential backoff to avoid overwhelming the API during outages
const delay = Math.min(1000 * Math.pow(2, retryCount), 30000)

// ❌ BAD: Stating the obvious
// Increment counter by 1
count++
```

**Remember**: Code quality is not negotiable. Clear, maintainable code enables rapid development and confident refactoring.
