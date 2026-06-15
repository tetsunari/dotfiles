---
name: coding
description: TypeScript・JavaScript・React・Node.js開発時には常に適用する。コードを実装する、コーディング標準を確認したい、ベストプラクティスに従って実装したい時に必ず使う。Universal coding standards, best practices, and patterns.
context: fork
allowed-tools: Read, Glob
---

# Coding Standards & Best Practices

Universal coding standards applicable across all projects.

**See also**: `rules/coding-style.md` for Immutability, Error Handling, Input Validation patterns. `rules/patterns.md` for ApiResponse, useDebounce, Repository patterns. `references/code-examples.md` for detailed TypeScript/React/API/Testing code examples.

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

## File Organization

### Project Structure

> **注意**: 以下は Next.js App Router プロジェクトの例。他フレームワークでは適宜読み替える。

```
src/
├── app/                    # Next.js App Router
│   ├── api/               # API routes
│   ├── markets/           # Feature pages
│   └── (auth)/           # Auth pages (route groups)
├── components/            # React components
│   ├── ui/               # Generic UI components
│   ├── forms/            # Form components
│   └── layouts/          # Layout components
├── hooks/                # Custom React hooks
├── lib/                  # Utilities and configs
│   ├── api/             # API clients
│   ├── utils/           # Helper functions
│   └── constants/       # Constants
├── types/                # TypeScript types
└── styles/              # Global styles
```

### File Naming

```
components/Button.tsx          # PascalCase for components
hooks/useAuth.ts              # camelCase with 'use' prefix
lib/formatDate.ts             # camelCase for utilities
types/market.types.ts         # camelCase with .types suffix
```

## Code Smell Detection

Watch for these anti-patterns and apply early returns, named constants, and function splitting:

- **Long Functions**: Functions > 50 lines → split into smaller functions
- **Deep Nesting**: 5+ levels → use early returns
- **Magic Numbers**: Unexplained numbers → use named constants
- **Vague Names**: `q`, `flag`, `x` → use descriptive names

See `references/code-examples.md` for ✅/❌ examples of each pattern.

**Remember**: Code quality is not negotiable. Clear, maintainable code enables rapid development and confident refactoring.
