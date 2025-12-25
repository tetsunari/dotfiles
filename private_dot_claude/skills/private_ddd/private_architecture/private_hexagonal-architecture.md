# Hexagonal Architecture (Ports & Adapters)

## Overview

Hexagonal Architecture, also known as **Ports and Adapters**, was created by Alistair Cockburn. It emphasizes the isolation of core business logic from external concerns by defining clear boundaries through ports and adapters.

## Visual Representation

```
                    ┌─────────────────────────┐
                    │     REST API            │
                    │     (Adapter)           │
                    └──────────┬──────────────┘
                               │
                    ┌──────────▼──────────────┐
                    │   Controller Port       │
                    │   (Input Port)          │
                    └──────────┬──────────────┘
                               │
        ┌──────────────────────▼──────────────────────┐
        │                                              │
        │          APPLICATION CORE                    │
        │      (Business Logic / Domain)               │
        │                                              │
        │   ┌────────────────────────────────┐         │
        │   │  Use Cases / Domain Services   │         │
        │   └────────────────────────────────┘         │
        │                                              │
        └──────────────────────┬──────────────────────┘
                               │
                    ┌──────────▼──────────────┐
                    │  Repository Port        │
                    │  (Output Port)          │
                    └──────────┬──────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
┌─────────▼──────┐  ┌─────────▼──────┐  ┌─────────▼──────┐
│   DynamoDB     │  │   PostgreSQL   │  │   In-Memory    │
│   (Adapter)    │  │   (Adapter)    │  │   (Adapter)    │
└────────────────┘  └────────────────┘  └────────────────┘
```

## Core Concepts

### Ports
**Interfaces that define how the application core communicates with the outside world**

- **Input Ports (Driving/Primary)**: How external actors interact with the application
  - Example: `CreateTaskUseCase` interface
  - Called BY adapters

- **Output Ports (Driven/Secondary)**: How the application interacts with external systems
  - Example: `TaskRepository` interface
  - Implemented BY adapters

### Adapters
**Concrete implementations that connect ports to external systems**

- **Input Adapters (Driving/Primary)**: Convert external requests into application calls
  - Example: REST controller, GraphQL resolver, CLI command

- **Output Adapters (Driven/Secondary)**: Implement output ports
  - Example: Database repository, email service, external API client

## Implementation Structure

```
src/
├── core/                          # Application Core (Hexagon)
│   ├── domain/
│   │   ├── model/
│   │   │   ├── task.entity.ts
│   │   │   ├── task-id.value-object.ts
│   │   │   └── task-status.value-object.ts
│   │   └── service/
│   │       └── task.domain-service.ts
│   │
│   └── application/
│       ├── port/
│       │   ├── input/           # Input Ports (Use Case Interfaces)
│       │   │   ├── create-task.use-case.ts
│       │   │   └── get-task.use-case.ts
│       │   │
│       │   └── output/          # Output Ports (Repository Interfaces)
│       │       ├── task.repository.ts
│       │       └── notification.service.ts
│       │
│       ├── usecase/             # Use Case Implementations
│       │   ├── create-task.usecase.impl.ts
│       │   └── get-task.usecase.impl.ts
│       │
│       └── dto/
│           └── task.dto.ts
│
└── adapter/                      # Adapters (Outside Hexagon)
    ├── input/                    # Input Adapters (Driving)
    │   ├── rest/
    │   │   └── task.controller.ts
    │   ├── graphql/
    │   │   └── task.resolver.ts
    │   └── cli/
    │       └── task.command.ts
    │
    └── output/                   # Output Adapters (Driven)
        ├── persistence/
        │   ├── dynamodb-task.repository.adapter.ts
        │   └── postgres-task.repository.adapter.ts
        └── notification/
            └── ses-notification.adapter.ts
```

## Code Examples

### Input Port (Use Case Interface)

```typescript
// core/application/port/input/create-task.use-case.ts
export interface CreateTaskUseCase {
  execute(request: CreateTaskRequest): Promise<TaskResponse>;
}

export interface CreateTaskRequest {
  title: string;
}

export interface TaskResponse {
  id: string;
  title: string;
  status: string;
}
```

### Input Port Implementation

```typescript
// core/application/usecase/create-task.usecase.impl.ts
export class CreateTaskUseCaseImpl implements CreateTaskUseCase {
  constructor(
    private readonly taskRepository: TaskRepository  // Output Port
  ) {}

  async execute(request: CreateTaskRequest): Promise<TaskResponse> {
    // Core business logic
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

### Output Port (Repository Interface)

```typescript
// core/application/port/output/task.repository.ts
export interface TaskRepository {
  save(task: Task): Promise<void>;
  findById(id: TaskId): Promise<Task | null>;
  findAll(): Promise<Task[]>;
  delete(id: TaskId): Promise<void>;
}
```

### Input Adapter (REST Controller)

```typescript
// adapter/input/rest/task.controller.ts
export class TaskController {
  constructor(
    private readonly createTaskUseCase: CreateTaskUseCase  // Input Port
  ) {}

  async createTask(req: Request, res: Response): Promise<void> {
    try {
      // Adapter converts HTTP request to use case input
      const result = await this.createTaskUseCase.execute({
        title: req.body.title
      });

      // Adapter converts use case output to HTTP response
      res.status(201).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
}
```

### Output Adapter (DynamoDB Repository)

```typescript
// adapter/output/persistence/dynamodb-task.repository.adapter.ts
export class DynamoDBTaskRepositoryAdapter implements TaskRepository {
  constructor(private readonly client: DynamoDBClient) {}

  async save(task: Task): Promise<void> {
    const item = {
      PK: `TASK#${task.getId().toString()}`,
      SK: `TASK#${task.getId().toString()}`,
      title: task.getTitle(),
      status: task.getStatus().toString(),
      createdAt: task.getCreatedAt().toISOString()
    };

    await this.client.send(new PutItemCommand({
      TableName: 'Tasks',
      Item: marshall(item)
    }));
  }

  async findById(id: TaskId): Promise<Task | null> {
    const result = await this.client.send(new GetItemCommand({
      TableName: 'Tasks',
      Key: marshall({
        PK: `TASK#${id.toString()}`,
        SK: `TASK#${id.toString()}`
      })
    }));

    if (!result.Item) return null;

    const item = unmarshall(result.Item);
    return Task.reconstruct(
      item.PK.replace('TASK#', ''),
      item.title,
      item.status,
      new Date(item.createdAt)
    );
  }

  // ... other methods
}
```

## Dependency Injection Setup

```typescript
// main.ts (Composition Root)
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';

// Create adapters
const dynamoClient = new DynamoDBClient({ region: 'us-east-1' });
const taskRepository = new DynamoDBTaskRepositoryAdapter(dynamoClient);

// Create use cases with dependencies
const createTaskUseCase = new CreateTaskUseCaseImpl(taskRepository);
const getTaskUseCase = new GetTaskUseCaseImpl(taskRepository);

// Create input adapters
const taskController = new TaskController(
  createTaskUseCase,
  getTaskUseCase
);

// Wire up to framework (Express, Lambda, etc.)
app.post('/tasks', (req, res) => taskController.createTask(req, res));
```

## Benefits

### 1. **Technology Independence**
The core is completely independent of frameworks and databases.

```typescript
// Can swap from DynamoDB to PostgreSQL without changing core
const taskRepository = new PostgresTaskRepositoryAdapter(pgClient);
// OR
const taskRepository = new DynamoDBTaskRepositoryAdapter(dynamoClient);

// Use case doesn't change
const useCase = new CreateTaskUseCaseImpl(taskRepository);
```

### 2. **Testability**
Easy to test core logic in isolation.

```typescript
describe('CreateTaskUseCase', () => {
  it('should create task', async () => {
    // Mock output port
    const mockRepository: TaskRepository = {
      save: jest.fn().mockResolvedValue(undefined),
      // ... other methods
    };

    const useCase = new CreateTaskUseCaseImpl(mockRepository);
    await useCase.execute({ title: 'Test Task' });

    expect(mockRepository.save).toHaveBeenCalled();
  });
});
```

### 3. **Multiple Input/Output Adapters**
Support multiple interfaces simultaneously.

```
REST API ─────┐
              ├──► Core ───► DynamoDB
GraphQL ──────┤         └──► PostgreSQL
              │         └──► In-Memory (testing)
CLI ──────────┘
```

### 4. **Clear Boundaries**
Explicit contracts between core and external world.

## Common Patterns

### Pattern 1: Multiple Adapters for Same Port

```typescript
// Same output port, different adapters
interface TaskRepository { /* ... */ }

class DynamoDBAdapter implements TaskRepository { /* ... */ }
class PostgresAdapter implements TaskRepository { /* ... */ }
class InMemoryAdapter implements TaskRepository { /* ... */ }

// Choose adapter based on environment
const repository = process.env.DB_TYPE === 'dynamo'
  ? new DynamoDBAdapter(dynamoClient)
  : new PostgresAdapter(pgClient);
```

### Pattern 2: Adapter Composition

```typescript
// Composite adapter combining multiple services
class NotificationAdapter implements NotificationPort {
  constructor(
    private readonly emailService: EmailService,
    private readonly smsService: SMSService
  ) {}

  async notify(user: User, message: string): Promise<void> {
    await Promise.all([
      this.emailService.send(user.email, message),
      this.smsService.send(user.phone, message)
    ]);
  }
}
```

### Pattern 3: Event-Driven Adapters

```typescript
// Event bus adapter
class EventBusAdapter implements DomainEventPublisher {
  constructor(private readonly eventBridge: EventBridgeClient) {}

  async publish(event: DomainEvent): Promise<void> {
    await this.eventBridge.send(new PutEventsCommand({
      Entries: [{
        Source: 'task-service',
        DetailType: event.type,
        Detail: JSON.stringify(event.payload)
      }]
    }));
  }
}
```

## Testing Strategy

### Unit Tests (Core Only)
```typescript
// Test domain logic in complete isolation
describe('Task Entity', () => {
  it('should not allow empty title', () => {
    expect(() => Task.create('')).toThrow('Title is required');
  });
});
```

### Integration Tests (Core + Mock Adapters)
```typescript
// Test use cases with mock adapters
describe('CreateTaskUseCase Integration', () => {
  it('should orchestrate task creation', async () => {
    const mockRepo = createMockRepository();
    const useCase = new CreateTaskUseCaseImpl(mockRepo);

    await useCase.execute({ title: 'Test' });

    expect(mockRepo.save).toHaveBeenCalledWith(
      expect.objectContaining({ title: 'Test' })
    );
  });
});
```

### Adapter Tests (Real External Systems)
```typescript
// Test real adapters against actual infrastructure
describe('DynamoDBAdapter', () => {
  let adapter: DynamoDBTaskRepositoryAdapter;

  beforeAll(() => {
    // Use real DynamoDB Local or test environment
    adapter = new DynamoDBTaskRepositoryAdapter(testDynamoClient);
  });

  it('should persist and retrieve task', async () => {
    const task = Task.create('Integration Test');
    await adapter.save(task);

    const retrieved = await adapter.findById(task.getId());
    expect(retrieved?.getTitle()).toBe('Integration Test');
  });
});
```

## When to Use Hexagonal Architecture

### ✅ Good Fit
- Applications with multiple input channels (REST, GraphQL, CLI, Events)
- Systems requiring database/technology flexibility
- Long-lived projects needing maintainability
- Complex business logic requiring isolation
- Teams practicing TDD/BDD

### ❌ Not Ideal
- Simple CRUD applications
- Prototypes or short-lived projects
- Small teams unfamiliar with the pattern
- Very tight coupling to specific framework/database

## Comparison with Layered Architecture

| Aspect | Layered | Hexagonal |
|--------|---------|-----------|
| **Structure** | Horizontal layers | Core + surrounding adapters |
| **Dependencies** | Top-down (presentation → infrastructure) | Inward (all → core) |
| **Flexibility** | Medium (can swap infrastructure) | High (easily swap any adapter) |
| **Complexity** | Lower | Higher (more abstractions) |
| **Testing** | Good | Excellent |
| **Learning Curve** | Gentler | Steeper |

---

See also:
- `layered-architecture.md` for traditional DDD structure
- `clean-architecture.md` for Uncle Bob's dependency inversion approach
