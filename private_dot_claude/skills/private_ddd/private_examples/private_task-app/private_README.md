# Task Management Application - DDD Example

This is a simple task management application demonstrating Domain-Driven Design principles in TypeScript.

## Domain Model

### Entities
- **Task**: Core entity representing a task with business logic

### Value Objects
- **TaskId**: Unique identifier (UUID)
- **TaskStatus**: Status enum (pending/completed)

### Repository
- **TaskRepository**: Interface for task persistence

### Use Cases
- **CreateTaskUseCase**: Create a new task

## File Structure

```
task-app/
├── task.entity.ts                         # Domain Entity
├── task-id.value-object.ts                # Value Object
├── task-status.value-object.ts            # Value Object
├── task.repository.ts                     # Repository Interface
├── create-task.usecase.ts                 # Application Use Case
├── in-memory-task.repository.impl.ts      # Infrastructure Implementation
└── README.md
```

## Usage Example

```typescript
// Infrastructure layer - setup
const taskRepository = new InMemoryTaskRepository();

// Application layer - use case
const createTaskUseCase = new CreateTaskUseCase(taskRepository);

// Execute use case
const result = await createTaskUseCase.execute({
  title: 'Buy groceries'
});

console.log(result);
// {
//   id: '123e4567-e89b-12d3-a456-426614174000',
//   title: 'Buy groceries',
//   status: 'pending',
//   createdAt: '2024-01-15T10:30:00.000Z'
// }
```

## Domain Logic Examples

### Creating a Task
```typescript
// Domain validation happens in factory method
const task = Task.create('Buy milk');  // ✅ Valid

const task = Task.create('');          // ❌ Throws: "Task title is required"
```

### Completing a Task
```typescript
const task = Task.create('Buy milk');
task.complete();  // ✅ Changes status to 'completed'

task.complete();  // ❌ Throws: "Task is already completed"
```

### Checking if Overdue
```typescript
const task = Task.create('Old task');

// After 8 days
task.isOverdue();  // true (pending for more than 7 days)
```

## Layer Boundaries

### Domain Layer (Core Business Logic)
- `task.entity.ts` - Entity with business rules
- `task-id.value-object.ts` - Identity value object
- `task-status.value-object.ts` - Status value object
- `task.repository.ts` - Repository interface

**Dependencies**: NONE (completely independent)

### Application Layer (Use Cases)
- `create-task.usecase.ts` - Orchestrates task creation

**Dependencies**: Domain layer only

### Infrastructure Layer (Technical Implementation)
- `in-memory-task.repository.impl.ts` - Repository implementation

**Dependencies**: Domain layer (implements TaskRepository interface)

## Testing Example

```typescript
describe('Task Entity', () => {
  it('should create task with pending status', () => {
    const task = Task.create('Test task');

    expect(task.getStatus().isPending()).toBe(true);
    expect(task.getTitle()).toBe('Test task');
  });

  it('should throw error for empty title', () => {
    expect(() => Task.create('')).toThrow('Task title is required');
  });

  it('should complete task', () => {
    const task = Task.create('Test task');
    task.complete();

    expect(task.getStatus().isCompleted()).toBe(true);
    expect(task.getCompletedAt()).toBeInstanceOf(Date);
  });

  it('should not complete already completed task', () => {
    const task = Task.create('Test task');
    task.complete();

    expect(() => task.complete()).toThrow('Task is already completed');
  });
});
```

## Extending This Example

### Add More Use Cases
```typescript
// complete-task.usecase.ts
export class CompleteTaskUseCase {
  constructor(private readonly taskRepository: TaskRepository) {}

  async execute(taskId: string): Promise<TaskResponse> {
    const id = TaskId.fromString(taskId);
    const task = await this.taskRepository.findById(id);

    if (!task) {
      throw new Error('Task not found');
    }

    task.complete();
    await this.taskRepository.save(task);

    return this.toResponse(task);
  }
}
```

### Add DynamoDB Repository
```typescript
// dynamodb-task.repository.impl.ts
export class DynamoDBTaskRepository implements TaskRepository {
  constructor(private readonly client: DynamoDBClient) {}

  async save(task: Task): Promise<void> {
    const item = {
      PK: `TASK#${task.getId().toString()}`,
      SK: `TASK#${task.getId().toString()}`,
      title: task.getTitle(),
      status: task.getStatus().toString(),
      createdAt: task.getCreatedAt().toISOString(),
      completedAt: task.getCompletedAt()?.toISOString() || null
    };

    await this.client.send(new PutItemCommand({
      TableName: 'Tasks',
      Item: marshall(item)
    }));
  }

  // ... other methods
}
```

### Add REST Controller
```typescript
// task.controller.ts
export class TaskController {
  constructor(private readonly createTaskUseCase: CreateTaskUseCase) {}

  async createTask(req: Request, res: Response): Promise<void> {
    try {
      const result = await this.createTaskUseCase.execute({
        title: req.body.title
      });

      res.status(201).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
}
```

## Key DDD Principles Demonstrated

1. **Rich Domain Model**: Business logic lives in entities, not services
2. **Value Objects**: Immutable objects representing concepts (TaskId, TaskStatus)
3. **Repository Pattern**: Abstract persistence concerns from domain
4. **Use Cases**: Clear application services with single responsibility
5. **Dependency Inversion**: Domain doesn't depend on infrastructure
6. **Validation at Boundaries**: Domain validates its own invariants

## Production Considerations

When moving to production:

1. Replace `InMemoryTaskRepository` with real database implementation
2. Add proper error handling and logging
3. Implement DTOs for API requests/responses
4. Add authentication and authorization
5. Implement domain events for side effects
6. Add integration and E2E tests
7. Set up dependency injection container
8. Add API documentation (OpenAPI/Swagger)

---

This example follows modern DDD practices as outlined in the DDD skill documentation.
