# Directory Structure for DDD Projects

## Standard DDD Directory Organization

### Basic 4-Layer Structure

```
src/
├── domain/              # Business logic core
├── application/         # Use cases and orchestration
├── infrastructure/      # External implementations
└── presentation/        # User interface / API
```

## Detailed Structure

### Full Project Layout

```
project-root/
├── src/
│   ├── domain/
│   │   ├── model/
│   │   │   ├── entities/
│   │   │   ├── value-objects/
│   │   │   └── aggregates/
│   │   ├── repository/
│   │   ├── service/
│   │   ├── event/
│   │   └── exception/
│   │
│   ├── application/
│   │   ├── usecase/
│   │   ├── dto/
│   │   ├── service/
│   │   └── mapper/
│   │
│   ├── infrastructure/
│   │   ├── persistence/
│   │   │   ├── dynamodb/
│   │   │   ├── postgres/
│   │   │   └── redis/
│   │   ├── messaging/
│   │   ├── external/
│   │   └── config/
│   │
│   ├── presentation/
│   │   ├── rest/
│   │   │   ├── controller/
│   │   │   └── middleware/
│   │   ├── graphql/
│   │   │   ├── resolver/
│   │   │   └── schema/
│   │   └── lambda/
│   │       └── handler/
│   │
│   ├── shared/
│   │   ├── types/
│   │   ├── utils/
│   │   └── constants/
│   │
│   └── main.ts
│
├── test/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── docs/
├── scripts/
└── config/
```

## Layer-by-Layer Breakdown

### 1. Domain Layer (`domain/`)

**Purpose**: Contains all business logic and rules. No dependencies on outer layers.

```
domain/
├── model/
│   ├── entities/
│   │   ├── task.entity.ts
│   │   ├── user.entity.ts
│   │   └── project.entity.ts
│   │
│   ├── value-objects/
│   │   ├── task-id.value-object.ts
│   │   ├── task-status.value-object.ts
│   │   ├── email.value-object.ts
│   │   └── phone-number.value-object.ts
│   │
│   └── aggregates/
│       ├── order.aggregate.ts
│       └── shopping-cart.aggregate.ts
│
├── repository/              # Interfaces only
│   ├── task.repository.ts
│   ├── user.repository.ts
│   └── project.repository.ts
│
├── service/
│   ├── task-completion.domain-service.ts
│   └── pricing.domain-service.ts
│
├── event/
│   ├── task-created.event.ts
│   ├── task-completed.event.ts
│   └── user-registered.event.ts
│
└── exception/
    ├── domain.exception.ts
    ├── invalid-task.exception.ts
    └── task-not-found.exception.ts
```

#### Alternative: Flat Model Structure (Simpler Projects)

```
domain/
├── model/
│   ├── task.entity.ts
│   ├── task-id.value-object.ts
│   ├── task-status.value-object.ts
│   └── user.entity.ts
│
├── repository/
│   └── task.repository.ts
│
└── service/
    └── task.domain-service.ts
```

---

### 2. Application Layer (`application/`)

**Purpose**: Orchestrate domain objects to fulfill use cases.

```
application/
├── usecase/
│   ├── task/
│   │   ├── create-task.usecase.ts
│   │   ├── complete-task.usecase.ts
│   │   ├── delete-task.usecase.ts
│   │   └── get-task.usecase.ts
│   │
│   └── user/
│       ├── register-user.usecase.ts
│       └── authenticate-user.usecase.ts
│
├── dto/
│   ├── task/
│   │   ├── create-task.request.dto.ts
│   │   ├── update-task.request.dto.ts
│   │   └── task.response.dto.ts
│   │
│   └── user/
│       ├── register-user.request.dto.ts
│       └── user.response.dto.ts
│
├── service/                  # Application services (optional)
│   └── task.service.ts
│
└── mapper/
    ├── task.mapper.ts
    └── user.mapper.ts
```

#### Alternative: Flat Structure (Simpler Projects)

```
application/
├── usecase/
│   ├── create-task.usecase.ts
│   ├── complete-task.usecase.ts
│   └── get-task.usecase.ts
│
└── dto/
    ├── create-task.request.dto.ts
    └── task.response.dto.ts
```

---

### 3. Infrastructure Layer (`infrastructure/`)

**Purpose**: Implement technical details and external integrations.

```
infrastructure/
├── persistence/
│   ├── dynamodb/
│   │   ├── dynamodb-task.repository.impl.ts
│   │   ├── dynamodb-user.repository.impl.ts
│   │   ├── dynamodb-client.config.ts
│   │   └── mapper/
│   │       └── task.dynamodb.mapper.ts
│   │
│   ├── postgres/
│   │   ├── postgres-task.repository.impl.ts
│   │   ├── task.model.ts            # TypeORM/Prisma model
│   │   └── migrations/
│   │       └── 001-create-tasks.migration.ts
│   │
│   └── redis/
│       └── redis-cache.adapter.ts
│
├── messaging/
│   ├── sqs/
│   │   └── sqs-event-publisher.adapter.ts
│   │
│   └── eventbridge/
│       └── eventbridge-publisher.adapter.ts
│
├── external/
│   ├── ses-email.adapter.ts
│   ├── twilio-sms.adapter.ts
│   └── stripe-payment.adapter.ts
│
└── config/
    ├── database.config.ts
    ├── aws.config.ts
    └── env.config.ts
```

---

### 4. Presentation Layer (`presentation/`)

**Purpose**: Handle user interactions and external requests.

```
presentation/
├── rest/
│   ├── controller/
│   │   ├── task.controller.ts
│   │   ├── user.controller.ts
│   │   └── health.controller.ts
│   │
│   ├── middleware/
│   │   ├── auth.middleware.ts
│   │   ├── logging.middleware.ts
│   │   └── error-handler.middleware.ts
│   │
│   └── validator/
│       └── task.validator.ts
│
├── graphql/
│   ├── resolver/
│   │   ├── task.resolver.ts
│   │   └── user.resolver.ts
│   │
│   └── schema/
│       ├── task.schema.graphql
│       └── user.schema.graphql
│
├── lambda/
│   ├── handler/
│   │   ├── task-get.handler.ts
│   │   ├── task-create.handler.ts
│   │   └── task-delete.handler.ts
│   │
│   └── event/
│       └── dynamodb-stream.handler.ts
│
└── cli/
    └── command/
        └── seed-database.command.ts
```

---

### 5. Shared (`shared/`)

**Purpose**: Code used across multiple layers (use sparingly).

```
shared/
├── types/
│   ├── common.type.ts
│   └── result.type.ts
│
├── utils/
│   ├── date.util.ts
│   └── validation.util.ts
│
├── constants/
│   └── app.constant.ts
│
└── interface/
    └── logger.interface.ts
```

**⚠️ Warning**: Don't overuse `shared/`. Most code belongs in a specific layer.

---

## Bounded Context Organization

For larger applications, organize by bounded contexts:

```
src/
├── task-management/          # Bounded Context 1
│   ├── domain/
│   ├── application/
│   ├── infrastructure/
│   └── presentation/
│
├── user-management/          # Bounded Context 2
│   ├── domain/
│   ├── application/
│   ├── infrastructure/
│   └── presentation/
│
└── notification/             # Bounded Context 3
    ├── domain/
    ├── application/
    ├── infrastructure/
    └── presentation/
```

### Alternative: Hybrid Approach

```
src/
├── contexts/
│   ├── task-management/
│   │   ├── domain/
│   │   ├── application/
│   │   └── infrastructure/
│   │
│   └── user-management/
│       ├── domain/
│       ├── application/
│       └── infrastructure/
│
└── shared/
    ├── presentation/         # Shared API framework
    └── infrastructure/       # Shared database connection
```

---

## Hexagonal Architecture Structure

For ports & adapters pattern:

```
src/
├── core/                     # The Hexagon
│   ├── domain/
│   │   └── model/
│   │
│   └── application/
│       ├── port/
│       │   ├── input/        # Use case interfaces
│       │   └── output/       # Repository interfaces
│       │
│       └── usecase/          # Use case implementations
│
└── adapter/                  # Outside the Hexagon
    ├── input/                # Driving adapters
    │   ├── rest/
    │   ├── graphql/
    │   └── cli/
    │
    └── output/               # Driven adapters
        ├── persistence/
        ├── messaging/
        └── external/
```

---

## Monorepo Structure

For multiple services in one repository:

```
packages/
├── task-service/
│   ├── src/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── presentation/
│   └── package.json
│
├── user-service/
│   ├── src/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── presentation/
│   └── package.json
│
└── shared/
    ├── domain-primitives/
    │   └── src/
    │       └── value-objects/
    │           ├── email.value-object.ts
    │           └── id.value-object.ts
    └── package.json
```

---

## AWS Lambda Specific Structure

```
lambda/
├── tasks/
│   ├── domain/
│   │   └── model/
│   │       └── task.entity.ts
│   │
│   ├── application/
│   │   └── usecase/
│   │       ├── create-task.usecase.ts
│   │       └── get-task.usecase.ts
│   │
│   ├── infrastructure/
│   │   └── persistence/
│   │       └── dynamodb-task.repository.impl.ts
│   │
│   └── handlers/             # Lambda handlers
│       ├── task-get.ts
│       ├── task-create.ts
│       └── task-delete.ts
│
└── shared/
    └── libs/
```

---

## Testing Directory Structure

### Co-located Tests

```
src/
├── domain/
│   ├── model/
│   │   ├── task.entity.ts
│   │   └── task.entity.spec.ts       # Next to source
```

### Separate Test Directory

```
test/
├── unit/
│   ├── domain/
│   │   └── task.entity.spec.ts
│   │
│   └── application/
│       └── create-task.usecase.spec.ts
│
├── integration/
│   └── infrastructure/
│       └── dynamodb-task.repository.integration.spec.ts
│
└── e2e/
    └── task-api.e2e.spec.ts
```

---

## Index Files (Barrel Exports)

Use `index.ts` files to simplify imports:

```
domain/model/
├── task.entity.ts
├── task-id.value-object.ts
├── task-status.value-object.ts
└── index.ts
```

**index.ts**:
```typescript
export * from './task.entity';
export * from './task-id.value-object';
export * from './task-status.value-object';
```

**Usage**:
```typescript
// Instead of:
import { Task } from './domain/model/task.entity';
import { TaskId } from './domain/model/task-id.value-object';

// You can:
import { Task, TaskId } from './domain/model';
```

---

## Decision Tree: Which Structure?

### Small Project (Single Bounded Context)
```
src/
├── domain/
│   ├── model/              # Flat structure
│   ├── repository/
│   └── service/
├── application/
│   ├── usecase/            # Flat structure
│   └── dto/
├── infrastructure/
└── presentation/
```

### Medium Project (Multiple Related Entities)
```
src/
├── domain/
│   ├── model/
│   │   ├── entities/       # Grouped by type
│   │   └── value-objects/
│   └── repository/
├── application/
│   ├── usecase/
│   │   ├── task/           # Grouped by feature
│   │   └── user/
│   └── dto/
│       ├── task/
│       └── user/
└── ...
```

### Large Project (Multiple Bounded Contexts)
```
src/
├── contexts/
│   ├── task-management/    # Full DDD layers per context
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── presentation/
│   │
│   └── user-management/
│       └── ...
└── shared/
```

---

**See also**:
- `file-naming.md` - How to name individual files
- `../examples/task-app/` - Complete working example
