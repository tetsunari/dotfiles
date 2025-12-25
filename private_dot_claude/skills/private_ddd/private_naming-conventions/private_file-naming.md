# File Naming Conventions for DDD TypeScript Projects

## Modern TypeScript Naming Standard (2024-2025)

The **dot-separated** naming convention has become the de facto standard for TypeScript projects, especially in Angular, NestJS, and modern DDD applications.

## General Pattern

```
{name}.{type}.ts
```

### Examples
```
task.entity.ts
task-id.value-object.ts
create-task.usecase.ts
task.repository.ts
task.controller.ts
task.service.ts
```

## Type Suffixes Reference

### Domain Layer

| Type | Suffix | Example |
|------|--------|---------|
| Entity | `.entity.ts` | `task.entity.ts`, `user.entity.ts` |
| Value Object | `.value-object.ts` | `task-id.value-object.ts`, `email.value-object.ts` |
| Aggregate Root | `.aggregate.ts` | `order.aggregate.ts`, `cart.aggregate.ts` |
| Domain Service | `.domain-service.ts` | `pricing.domain-service.ts` |
| Repository Interface | `.repository.ts` | `task.repository.ts` |
| Domain Event | `.event.ts` | `task-created.event.ts` |
| Domain Exception | `.exception.ts` | `invalid-task.exception.ts` |

### Application Layer

| Type | Suffix | Example |
|------|--------|---------|
| Use Case | `.usecase.ts` | `create-task.usecase.ts` |
| Application Service | `.service.ts` | `task.service.ts` |
| DTO (Request) | `.request.dto.ts` | `create-task.request.dto.ts` |
| DTO (Response) | `.response.dto.ts` | `task.response.dto.ts` |
| DTO (Generic) | `.dto.ts` | `task.dto.ts` |
| Query | `.query.ts` | `get-tasks.query.ts` |
| Command | `.command.ts` | `create-task.command.ts` |

### Infrastructure Layer

| Type | Suffix | Example |
|------|--------|---------|
| Repository Implementation | `.repository.impl.ts` | `dynamodb-task.repository.impl.ts` |
| Adapter | `.adapter.ts` | `ses-email.adapter.ts` |
| Mapper | `.mapper.ts` | `task.mapper.ts` |
| Database Model | `.model.ts` | `task.model.ts` (ORM/ODM schema) |
| Migration | `.migration.ts` | `001-create-tasks.migration.ts` |
| Seeder | `.seeder.ts` | `tasks.seeder.ts` |

### Presentation Layer

| Type | Suffix | Example |
|------|--------|---------|
| Controller | `.controller.ts` | `task.controller.ts` |
| Handler (Lambda/Event) | `.handler.ts` | `task-created.handler.ts` |
| Resolver (GraphQL) | `.resolver.ts` | `task.resolver.ts` |
| Middleware | `.middleware.ts` | `auth.middleware.ts` |
| Guard | `.guard.ts` | `jwt.guard.ts` |
| Interceptor | `.interceptor.ts` | `logging.interceptor.ts` |

### Testing

| Type | Suffix | Example |
|------|--------|---------|
| Unit Test | `.spec.ts` | `task.entity.spec.ts` |
| Integration Test | `.integration.spec.ts` | `create-task.integration.spec.ts` |
| E2E Test | `.e2e.spec.ts` | `task-api.e2e.spec.ts` |
| Test Helper | `.helper.ts` | `test-data.helper.ts` |
| Mock | `.mock.ts` | `task.repository.mock.ts` |
| Fixture | `.fixture.ts` | `task.fixture.ts` |

### Configuration & Utilities

| Type | Suffix | Example |
|------|--------|---------|
| Configuration | `.config.ts` | `database.config.ts` |
| Constants | `.constant.ts` | `task-status.constant.ts` |
| Type Definitions | `.type.ts` | `common.type.ts` |
| Interface | `.interface.ts` | `logger.interface.ts` |
| Enum | `.enum.ts` | `task-priority.enum.ts` |
| Decorator | `.decorator.ts` | `validate.decorator.ts` |
| Factory | `.factory.ts` | `task.factory.ts` |
| Builder | `.builder.ts` | `task.builder.ts` |
| Module | `.module.ts` | `task.module.ts` (NestJS) |

## Naming Style: Kebab-case vs camelCase

### ✅ Recommended: kebab-case

```typescript
// Good
task-status.value-object.ts
create-task.usecase.ts
dynamodb-task.repository.impl.ts
```

### ❌ Avoid: camelCase

```typescript
// Avoid
taskStatus.valueObject.ts
createTask.usecase.ts
dynamodbTask.repository.impl.ts
```

### Reasons for Kebab-case

1. **Case-insensitive filesystems**: Windows/macOS don't distinguish `Task.ts` vs `task.ts`
2. **URL-friendly**: Works well in routing and web contexts
3. **Easier to read**: `create-user-account` vs `createUserAccount`
4. **Tool compatibility**: Better support in CLIs and build tools
5. **Industry standard**: Used by Angular, NestJS, Vue, etc.

## Multi-word Names

### For Complex Names

```typescript
// Entity with multiple words
user-profile.entity.ts
shopping-cart.aggregate.ts

// Value objects
email-address.value-object.ts
phone-number.value-object.ts

// Use cases
send-password-reset-email.usecase.ts
calculate-order-total.usecase.ts

// Repository implementations
postgres-user-profile.repository.impl.ts
```

## Directory + File Examples

### Domain Layer Structure
```
domain/
├── model/
│   ├── task.entity.ts
│   ├── task-id.value-object.ts
│   ├── task-status.value-object.ts
│   ├── task-priority.value-object.ts
│   └── task-title.value-object.ts
│
├── repository/
│   ├── task.repository.ts
│   └── user.repository.ts
│
├── service/
│   └── task-completion.domain-service.ts
│
└── event/
    ├── task-created.event.ts
    ├── task-completed.event.ts
    └── task-deleted.event.ts
```

### Application Layer Structure
```
application/
├── usecase/
│   ├── create-task.usecase.ts
│   ├── complete-task.usecase.ts
│   ├── delete-task.usecase.ts
│   └── get-task.usecase.ts
│
├── dto/
│   ├── create-task.request.dto.ts
│   ├── update-task.request.dto.ts
│   └── task.response.dto.ts
│
└── service/
    └── task.service.ts
```

### Infrastructure Layer Structure
```
infrastructure/
├── persistence/
│   ├── dynamodb/
│   │   ├── dynamodb-task.repository.impl.ts
│   │   └── dynamodb-client.config.ts
│   │
│   └── postgres/
│       ├── postgres-task.repository.impl.ts
│       └── task.model.ts
│
├── messaging/
│   └── sqs-event-publisher.adapter.ts
│
└── external/
    └── ses-email.adapter.ts
```

### Presentation Layer Structure
```
presentation/
├── rest/
│   ├── task.controller.ts
│   ├── user.controller.ts
│   └── middleware/
│       ├── auth.middleware.ts
│       └── logging.middleware.ts
│
├── graphql/
│   ├── task.resolver.ts
│   └── user.resolver.ts
│
└── lambda/
    ├── task-get.handler.ts
    ├── task-create.handler.ts
    └── task-delete.handler.ts
```

## Special Cases

### Generic vs Specific DTOs

```typescript
// Generic (shared across multiple use cases)
task.dto.ts

// Specific (tied to one use case)
create-task.request.dto.ts
update-task.request.dto.ts
task-list.response.dto.ts
```

### Repository Implementation Naming

```typescript
// Pattern: {technology}-{domain}.repository.impl.ts
dynamodb-task.repository.impl.ts
postgres-user.repository.impl.ts
redis-session.repository.impl.ts

// Alternative (when obvious):
task.repository.impl.ts  // If only one implementation
```

### Test File Naming

```typescript
// Same name as source file + .spec.ts
task.entity.ts          → task.entity.spec.ts
create-task.usecase.ts  → create-task.usecase.spec.ts

// Integration tests
create-task.usecase.ts  → create-task.usecase.integration.spec.ts

// E2E tests
task.controller.ts      → task.controller.e2e.spec.ts
```

## Index Files

```typescript
// Barrel exports
index.ts  // Not index.entity.ts or index.service.ts
```

### Example index.ts
```typescript
// domain/model/index.ts
export * from './task.entity';
export * from './task-id.value-object';
export * from './task-status.value-object';
```

## Benefits of This Convention

### 1. Instant Recognition
```bash
# Immediately know what each file contains
ls -la
create-task.usecase.ts          # Use case
task.entity.ts                  # Entity
dynamodb-task.repository.impl.ts # Repository implementation
```

### 2. Easy Searching

```bash
# Find all entities
find . -name "*.entity.ts"

# Find all use cases
find . -name "*.usecase.ts"

# Find all repository implementations
find . -name "*.repository.impl.ts"
```

### 3. IDE Auto-completion

Type `task.` and your IDE will show:
- `task.entity.ts`
- `task.repository.ts`
- `task.service.ts`
- `task.dto.ts`

### 4. Generator-Friendly

```bash
# CLI generators can easily create files
nest generate service task
# Creates: task.service.ts

nest generate controller task
# Creates: task.controller.ts
```

### 5. Team Consistency

Everyone on the team knows exactly where to put new files and what to name them.

## Migration from Legacy Naming

### Before (Mixed Conventions)
```
Task.ts
TaskRepository.ts
CreateTaskUseCase.ts
taskService.ts
```

### After (Consistent Modern Convention)
```
task.entity.ts
task.repository.ts
create-task.usecase.ts
task.service.ts
```

### Gradual Migration Strategy

1. Apply to new files immediately
2. Refactor on touch (when editing old files)
3. Module-by-module migration
4. Automated script for bulk rename (if needed)

---

**See also**:
- `directory-structure.md` - How to organize files into directories
- `../examples/task-app/` - Complete example following these conventions
