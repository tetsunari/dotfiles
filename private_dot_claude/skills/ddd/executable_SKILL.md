---
name: ddd
description: Domain-Driven Design (DDD) architecture guidance for TypeScript projects. Use when designing layered architecture, implementing entities/value objects/aggregates, structuring domain-driven applications, or applying modern DDD patterns (2024-2025).
context: fork
---

# Domain-Driven Design (DDD) Skill

This skill provides comprehensive guidance on modern Domain-Driven Design patterns and best practices for TypeScript applications.

## When to Use This Skill

- Designing new applications with DDD architecture
- Implementing entities, value objects, or aggregates
- Structuring layered/hexagonal/clean architecture
- Applying CQRS or event sourcing patterns
- Reviewing domain model designs
- Setting up DDD project structure

## What This Skill Provides

### 1. Architecture Patterns
- **Layered Architecture**: Traditional 4-layer DDD structure
- **Hexagonal Architecture**: Ports & Adapters pattern
- **Clean Architecture**: Dependency inversion with DDD
- **CQRS & Event Sourcing**: Modern scalable patterns

### 2. Naming Conventions
- **Dot-separated filenames**: Modern TypeScript convention
  - `task.entity.ts`, `task-id.value-object.ts`, `create-task.usecase.ts`
- **Kebab-case**: Recommended over camelCase for file names
- **Directory structure**: Standard DDD layer organization

### 3. Implementation Examples
- Task management application (simple CRUD)
- E-commerce domain (complex aggregates)
- Complete working code samples

### 4. Code Templates
- Entity boilerplate
- Value Object patterns
- Use Case structure
- Repository interfaces and implementations

### 5. Best Practices (2024-2025)
- Functional DDD with TypeScript
- Immutable value objects
- Smart constructors for validation
- Aggregate boundary design
- Domain event patterns

## Core DDD Principles

### Strategic Design
- **Bounded Contexts**: Divide domain into meaningful boundaries
- **Ubiquitous Language**: Shared vocabulary between developers and domain experts
- **Context Mapping**: Visualize relationships between contexts

### Tactical Design
- **Entity**: Objects with identity and lifecycle
- **Value Object**: Immutable objects without identity
- **Aggregate**: Consistency boundary with Aggregate Root
- **Domain Service**: Domain logic that doesn't belong to entities
- **Repository**: Abstraction for data persistence
- **Domain Event**: Important occurrences in the domain

## Quick Start

### Basic Layer Structure
```
src/
├── domain/              # Domain Layer (Business Logic Core)
│   ├── model/
│   │   ├── entities/
│   │   ├── value-objects/
│   │   └── aggregates/
│   ├── repository/      # Repository interfaces
│   └── service/         # Domain services
│
├── application/         # Application Layer (Use Cases)
│   ├── usecase/
│   └── dto/
│
├── infrastructure/      # Infrastructure Layer (External)
│   ├── persistence/
│   └── external/
│
└── presentation/        # Presentation Layer (API)
    └── api/
```

### Dependency Direction
```
presentation → application → domain ← infrastructure
```
**Key Rule**: Domain layer depends on nothing (all dependencies point inward)

## File Organization Examples

### Entity
```typescript
// task.entity.ts
export class Task {
  private constructor(
    private readonly id: TaskId,
    private title: string,
    private status: TaskStatus
  ) {}

  static create(title: string): Task {
    // Validation and creation logic
  }

  complete(): void {
    // Domain logic
  }
}
```

### Value Object
```typescript
// task-id.value-object.ts
export class TaskId {
  private constructor(private readonly value: string) {}

  static create(): TaskId {
    return new TaskId(crypto.randomUUID());
  }

  equals(other: TaskId): boolean {
    return this.value === other.value;
  }
}
```

### Use Case
```typescript
// create-task.usecase.ts
export class CreateTaskUseCase {
  constructor(private readonly taskRepository: TaskRepository) {}

  async execute(request: CreateTaskRequest): Promise<TaskResponse> {
    const task = Task.create(request.title);
    await this.taskRepository.save(task);
    return this.toResponse(task);
  }
}
```

## Reference Files

For detailed information, see:
- `architecture/` - Architectural pattern details
- `naming-conventions/` - File and directory naming rules
- `examples/` - Complete working examples
- `templates/` - Code boilerplate templates
- `best-practices/` - Modern DDD techniques

## Common Pitfalls to Avoid

1. **Anemic Domain Model**: Don't put all logic in services
2. **Over-engineering**: Start simple, add complexity when needed
3. **Ignoring Bounded Contexts**: Don't create one massive model
4. **Breaking Layer Dependencies**: Domain must not depend on outer layers
5. **Mutable Value Objects**: Always make them immutable

## Integration with Other Tools

- Works well with NestJS modules
- Compatible with TypeORM/Prisma for repositories
- Supports AWS Lambda handlers
- Integrates with event-driven architectures

---

**For architectural reviews and design validation, use the `ddd-architect` agent.**
