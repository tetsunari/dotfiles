# Layered Architecture in DDD

## Overview

Layered Architecture is the traditional approach to organizing DDD applications. It separates concerns into distinct horizontal layers, with strict dependency rules.

## The Four Layers

```
┌─────────────────────────────────────────────┐
│         Presentation Layer                  │
│  (Controllers, Handlers, API Routes)        │
└─────────────────┬───────────────────────────┘
                  │ depends on
┌─────────────────▼───────────────────────────┐
│         Application Layer                   │
│  (Use Cases, Application Services, DTOs)    │
└─────────────────┬───────────────────────────┘
                  │ depends on
┌─────────────────▼───────────────────────────┐
│         Domain Layer                        │
│  (Entities, Value Objects, Aggregates,      │
│   Domain Services, Repository Interfaces)   │
└─────────────────────────────────────────────┘
                  ▲
                  │ implements
┌─────────────────┴───────────────────────────┐
│         Infrastructure Layer                │
│  (Repository Implementations, Database,     │
│   External APIs, Messaging)                 │
└─────────────────────────────────────────────┘
```

## Layer Responsibilities

### 1. Presentation Layer
**Purpose**: Handle user interface and external interactions

**Contains**:
- Controllers (REST, GraphQL)
- Event handlers (Lambda, webhooks)
- Request/Response mapping
- Input validation (format level)

**Example**:
```typescript
// task.controller.ts
export class TaskController {
  constructor(private readonly createTaskUseCase: CreateTaskUseCase) {}

  async create(req: Request, res: Response): Promise<void> {
    const result = await this.createTaskUseCase.execute({
      title: req.body.title
    });
    res.status(201).json(result);
  }
}
```

**Dependencies**: Application layer only

---

### 2. Application Layer
**Purpose**: Orchestrate use cases and coordinate domain objects

**Contains**:
- Use cases (application services)
- DTOs (Data Transfer Objects)
- Application-level validation
- Transaction management
- Authorization

**Example**:
```typescript
// create-task.usecase.ts
export class CreateTaskUseCase {
  constructor(private readonly taskRepository: TaskRepository) {}

  async execute(request: CreateTaskRequest): Promise<TaskResponse> {
    // Orchestration logic
    const task = Task.create(request.title);
    await this.taskRepository.save(task);

    return {
      id: task.getId().toString(),
      title: task.getTitle(),
      status: task.getStatus().toString()
    };
  }
}
```

**Key Rules**:
- No business logic (delegate to domain)
- Coordinate multiple domain objects
- Handle transactions
- Convert between DTOs and domain objects

**Dependencies**: Domain layer only

---

### 3. Domain Layer (Core)
**Purpose**: Contain all business logic and rules

**Contains**:
- Entities (objects with identity)
- Value Objects (immutable descriptors)
- Aggregates (consistency boundaries)
- Domain Services (logic that doesn't fit in entities)
- Repository Interfaces (abstractions)
- Domain Events

**Example**:
```typescript
// task.entity.ts
export class Task {
  private constructor(
    private readonly id: TaskId,
    private title: string,
    private status: TaskStatus
  ) {}

  static create(title: string): Task {
    if (!title || title.trim().length === 0) {
      throw new DomainError('Title is required');
    }
    return new Task(TaskId.create(), title, TaskStatus.pending());
  }

  complete(): void {
    if (this.status.isCompleted()) {
      throw new DomainError('Task is already completed');
    }
    this.status = TaskStatus.completed();
  }
}
```

**Key Rules**:
- **No dependencies on outer layers** (most important!)
- Pure business logic only
- Rich domain model (not anemic)
- Validate invariants

**Dependencies**: NONE (completely independent)

---

### 4. Infrastructure Layer
**Purpose**: Provide technical implementations for domain abstractions

**Contains**:
- Repository implementations (DynamoDB, PostgreSQL)
- External API clients
- Message queue implementations
- File system operations
- Email/SMS services
- Cache implementations

**Example**:
```typescript
// dynamodb-task.repository.impl.ts
export class DynamoDBTaskRepository implements TaskRepository {
  constructor(private readonly dynamoClient: DynamoDBClient) {}

  async save(task: Task): Promise<void> {
    const item = {
      id: task.getId().toString(),
      title: task.getTitle(),
      status: task.getStatus().toString(),
      createdAt: task.getCreatedAt().toISOString()
    };

    await this.dynamoClient.send(new PutItemCommand({
      TableName: 'Tasks',
      Item: marshall(item)
    }));
  }

  async findById(id: TaskId): Promise<Task | null> {
    // Implementation details...
  }
}
```

**Dependencies**: Domain layer (implements interfaces)

---

## Directory Structure

```
src/
├── presentation/
│   ├── api/
│   │   ├── task.controller.ts
│   │   └── user.controller.ts
│   └── lambda/
│       └── task-handler.ts
│
├── application/
│   ├── usecase/
│   │   ├── create-task.usecase.ts
│   │   ├── complete-task.usecase.ts
│   │   └── get-task.usecase.ts
│   └── dto/
│       ├── create-task.request.dto.ts
│       └── task.response.dto.ts
│
├── domain/
│   ├── model/
│   │   ├── task.entity.ts
│   │   ├── task-id.value-object.ts
│   │   └── task-status.value-object.ts
│   ├── repository/
│   │   └── task.repository.ts
│   └── service/
│       └── task.domain-service.ts
│
└── infrastructure/
    ├── persistence/
    │   ├── dynamodb-task.repository.impl.ts
    │   └── in-memory-task.repository.impl.ts
    └── external/
        └── notification.service.impl.ts
```

## Dependency Rules

### ✅ Allowed Dependencies
```
Presentation → Application → Domain
Infrastructure → Domain (implements interfaces)
```

### ❌ Forbidden Dependencies
```
Domain → Application ❌
Domain → Infrastructure ❌
Domain → Presentation ❌
```

## Benefits

1. **Clear Separation of Concerns**: Each layer has distinct responsibility
2. **Testability**: Domain logic is isolated and easy to test
3. **Flexibility**: Can swap infrastructure without touching domain
4. **Team Organization**: Different teams can work on different layers
5. **Well-Understood**: Most developers are familiar with this pattern

## Drawbacks

1. **Rigid Structure**: Can be over-engineering for simple applications
2. **Boilerplate**: Requires more files and mapping code
3. **Learning Curve**: New developers need to understand layer boundaries
4. **Not Always Natural**: Some features span multiple layers awkwardly

## When to Use

**Good For**:
- Medium to large applications
- Long-term projects requiring maintainability
- Teams with clear role separation
- Applications with complex business rules

**Not Ideal For**:
- Simple CRUD applications
- Prototypes or proof-of-concepts
- Teams unfamiliar with DDD
- Very small microservices

## Testing Strategy

```typescript
// Domain Layer Tests (Unit Tests - No Dependencies)
describe('Task Entity', () => {
  it('should create task with pending status', () => {
    const task = Task.create('Buy milk');
    expect(task.getStatus().isPending()).toBe(true);
  });
});

// Application Layer Tests (Integration Tests - Mock Repositories)
describe('CreateTaskUseCase', () => {
  it('should create and save task', async () => {
    const mockRepo = createMockRepository();
    const useCase = new CreateTaskUseCase(mockRepo);

    await useCase.execute({ title: 'Test' });

    expect(mockRepo.save).toHaveBeenCalled();
  });
});

// Infrastructure Layer Tests (Integration Tests - Real DB)
describe('DynamoDBTaskRepository', () => {
  it('should save and retrieve task', async () => {
    const repo = new DynamoDBTaskRepository(testDynamoClient);
    const task = Task.create('Test');

    await repo.save(task);
    const retrieved = await repo.findById(task.getId());

    expect(retrieved?.getTitle()).toBe('Test');
  });
});
```

## Migration Path

### From Existing Codebase to Layered DDD

1. **Start with Domain**: Extract core business logic into domain entities
2. **Define Interfaces**: Create repository interfaces in domain layer
3. **Move Use Cases**: Extract orchestration logic to application layer
4. **Implement Infrastructure**: Move DB code to infrastructure layer
5. **Refactor Presentation**: Keep only input/output handling in controllers

### Gradual Approach
- Don't refactor everything at once
- Start with one bounded context
- Prove the value before expanding
- Keep both old and new code running in parallel initially

---

See also:
- `hexagonal-architecture.md` for ports & adapters pattern
- `clean-architecture.md` for dependency inversion approach
