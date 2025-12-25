# Functional DDD with TypeScript

## Overview

Functional programming and DDD can be combined to create more robust, testable domain models. This approach emphasizes:
- **Immutability** over mutation
- **Pure functions** over side effects
- **Composition** over inheritance
- **Types** as domain constraints

## Core Concepts

### 1. Immutable Value Objects

Value objects should always be immutable in functional DDD.

```typescript
// ✅ Functional approach - immutable
type Email = {
  readonly _brand: 'Email';
  readonly value: string;
};

const createEmail = (input: string): Result<Email, ValidationError> => {
  if (!isValidEmail(input)) {
    return Err(new ValidationError('Invalid email format'));
  }

  return Ok({ _brand: 'Email', value: input } as Email);
};

// ❌ OOP approach - mutable
class Email {
  private value: string;

  setValue(newValue: string): void {  // Mutation!
    this.value = newValue;
  }
}
```

### 2. Smart Constructors

Use factory functions that return `Result<T, E>` instead of throwing exceptions.

```typescript
// Result type (Either monad)
type Result<T, E> = Ok<T> | Err<E>;
type Ok<T> = { ok: true; value: T };
type Err<E> = { ok: false; error: E };

const Ok = <T>(value: T): Ok<T> => ({ ok: true, value });
const Err = <E>(error: E): Err<E> => ({ ok: false, error });

// Smart constructor with validation
type Price = {
  readonly _brand: 'Price';
  readonly amount: number;
  readonly currency: 'USD' | 'EUR' | 'JPY';
};

const createPrice = (
  amount: number,
  currency: 'USD' | 'EUR' | 'JPY'
): Result<Price, ValidationError> => {
  if (amount < 0) {
    return Err(new ValidationError('Price cannot be negative'));
  }

  if (amount > 1000000) {
    return Err(new ValidationError('Price exceeds maximum'));
  }

  return Ok({ _brand: 'Price', amount, currency } as Price);
};

// Usage
const priceResult = createPrice(99.99, 'USD');

if (priceResult.ok) {
  const price = priceResult.value;  // Type-safe access
  console.log(price.amount);
} else {
  console.error(priceResult.error.message);
}
```

### 3. Pure Domain Functions

Domain logic as pure functions that don't mutate state.

```typescript
type Order = {
  readonly id: OrderId;
  readonly items: readonly OrderItem[];
  readonly status: OrderStatus;
};

// ❌ OOP approach - mutation
class Order {
  addItem(item: OrderItem): void {
    this.items.push(item);  // Mutation!
  }
}

// ✅ Functional approach - returns new object
const addItemToOrder = (
  order: Order,
  item: OrderItem
): Result<Order, DomainError> => {
  if (order.status !== 'draft') {
    return Err(new DomainError('Cannot modify non-draft order'));
  }

  return Ok({
    ...order,
    items: [...order.items, item]  // New array
  });
};

// Usage
const orderResult = addItemToOrder(currentOrder, newItem);

if (orderResult.ok) {
  const updatedOrder = orderResult.value;
  // currentOrder remains unchanged
}
```

### 4. Type-Driven Design

Use TypeScript's type system to encode domain constraints.

```typescript
// Branded types for compile-time safety
type UserId = string & { readonly __brand: 'UserId' };
type OrderId = string & { readonly __brand: 'OrderId' };

const createUserId = (id: string): UserId => id as UserId;
const createOrderId = (id: string): OrderId => id as OrderId;

// Now you can't mix them up
const userId: UserId = createUserId('user-123');
const orderId: OrderId = createOrderId('order-456');

function getUserById(id: UserId) { /* ... */ }

getUserById(userId);   // ✅ OK
getUserById(orderId);  // ❌ Type error!
```

### 5. Phantom Types for States

Use phantom types to represent state transitions at compile time.

```typescript
// Order states as phantom types
type Draft = { readonly _state: 'draft' };
type Submitted = { readonly _state: 'submitted' };
type Shipped = { readonly _state: 'shipped' };

type Order<State> = {
  readonly id: OrderId;
  readonly items: readonly OrderItem[];
  readonly _phantom: State;
};

// State transitions
const submitOrder = (
  order: Order<Draft>
): Result<Order<Submitted>, DomainError> => {
  if (order.items.length === 0) {
    return Err(new DomainError('Cannot submit empty order'));
  }

  return Ok({
    ...order,
    _phantom: { _state: 'submitted' } as Submitted
  });
};

const shipOrder = (
  order: Order<Submitted>  // Can only ship submitted orders
): Order<Shipped> => ({
  ...order,
  _phantom: { _state: 'shipped' } as Shipped
});

// Usage
const draftOrder: Order<Draft> = createDraftOrder();
const submittedResult = submitOrder(draftOrder);

if (submittedResult.ok) {
  const shippedOrder = shipOrder(submittedResult.value);  // ✅ OK
}

// shipOrder(draftOrder);  // ❌ Type error - can't ship draft!
```

## Functional Patterns

### Pattern 1: Railway-Oriented Programming

Chain operations that can fail using Result type.

```typescript
// Helper functions for Result chaining
const map = <T, U, E>(
  result: Result<T, E>,
  fn: (value: T) => U
): Result<U, E> => {
  return result.ok ? Ok(fn(result.value)) : result;
};

const flatMap = <T, U, E>(
  result: Result<T, E>,
  fn: (value: T) => Result<U, E>
): Result<U, E> => {
  return result.ok ? fn(result.value) : result;
};

// Domain operations
const validateEmail = (email: string): Result<Email, ValidationError> => {
  // ...
};

const checkEmailNotTaken = (email: Email): Result<Email, DomainError> => {
  // ...
};

const createUser = (email: Email, name: string): Result<User, DomainError> => {
  // ...
};

// Chain operations
const registerUser = (emailInput: string, name: string): Result<User, Error> => {
  return flatMap(
    flatMap(
      validateEmail(emailInput),
      checkEmailNotTaken
    ),
    (email) => createUser(email, name)
  );
};
```

### Pattern 2: Algebraic Data Types (Discriminated Unions)

Model domain states with discriminated unions.

```typescript
// Order status as discriminated union
type OrderStatus =
  | { type: 'draft' }
  | { type: 'submitted'; submittedAt: Date }
  | { type: 'paid'; paidAt: Date; paymentMethod: string }
  | { type: 'shipped'; shippedAt: Date; trackingNumber: string }
  | { type: 'cancelled'; reason: string };

type Order = {
  readonly id: OrderId;
  readonly status: OrderStatus;
};

// Pattern matching for behavior
const getOrderDescription = (order: Order): string => {
  switch (order.status.type) {
    case 'draft':
      return 'Order is being prepared';
    case 'submitted':
      return `Order submitted on ${order.status.submittedAt}`;
    case 'paid':
      return `Paid via ${order.status.paymentMethod}`;
    case 'shipped':
      return `Shipped with tracking ${order.status.trackingNumber}`;
    case 'cancelled':
      return `Cancelled: ${order.status.reason}`;
  }
};

// Exhaustive checking ensures all cases are handled
const canModify = (order: Order): boolean => {
  switch (order.status.type) {
    case 'draft':
      return true;
    case 'submitted':
    case 'paid':
    case 'shipped':
    case 'cancelled':
      return false;
    // TypeScript ensures all cases are covered
  }
};
```

### Pattern 3: Optics (Lenses) for Immutable Updates

Update nested immutable structures.

```typescript
// Simple lens implementation
type Lens<S, A> = {
  get: (s: S) => A;
  set: (a: A) => (s: S) => S;
};

const lens = <S, A>(
  get: (s: S) => A,
  set: (a: A) => (s: S) => S
): Lens<S, A> => ({ get, set });

// Order structure
type Order = {
  readonly customer: Customer;
  readonly items: readonly OrderItem[];
};

type Customer = {
  readonly name: string;
  readonly email: Email;
};

// Lens for customer.email
const customerLens: Lens<Order, Customer> = lens(
  (order) => order.customer,
  (customer) => (order) => ({ ...order, customer })
);

const emailLens: Lens<Customer, Email> = lens(
  (customer) => customer.email,
  (email) => (customer) => ({ ...customer, email })
);

// Compose lenses
const composeLens = <A, B, C>(
  outer: Lens<A, B>,
  inner: Lens<B, C>
): Lens<A, C> => lens(
  (a) => inner.get(outer.get(a)),
  (c) => (a) => outer.set(inner.set(c)(outer.get(a)))(a)
);

const orderEmailLens = composeLens(customerLens, emailLens);

// Usage
const newEmail = createEmail('new@example.com').value;
const updatedOrder = orderEmailLens.set(newEmail)(order);
```

### Pattern 4: Functional Commands and Events

Model domain operations as pure data.

```typescript
// Command types
type CreateTaskCommand = {
  readonly type: 'CREATE_TASK';
  readonly title: string;
  readonly userId: UserId;
};

type CompleteTaskCommand = {
  readonly type: 'COMPLETE_TASK';
  readonly taskId: TaskId;
};

type Command = CreateTaskCommand | CompleteTaskCommand;

// Event types
type TaskCreatedEvent = {
  readonly type: 'TASK_CREATED';
  readonly taskId: TaskId;
  readonly title: string;
  readonly createdAt: Date;
};

type TaskCompletedEvent = {
  readonly type: 'TASK_COMPLETED';
  readonly taskId: TaskId;
  readonly completedAt: Date;
};

type Event = TaskCreatedEvent | TaskCompletedEvent;

// Pure command handler
const handleCommand = (
  command: Command,
  state: TaskState
): Result<readonly Event[], DomainError> => {
  switch (command.type) {
    case 'CREATE_TASK':
      return handleCreateTask(command, state);
    case 'COMPLETE_TASK':
      return handleCompleteTask(command, state);
  }
};

// Event sourcing - state from events
const applyEvent = (state: TaskState, event: Event): TaskState => {
  switch (event.type) {
    case 'TASK_CREATED':
      return {
        ...state,
        tasks: {
          ...state.tasks,
          [event.taskId]: {
            id: event.taskId,
            title: event.title,
            status: 'pending',
            createdAt: event.createdAt
          }
        }
      };
    case 'TASK_COMPLETED':
      return {
        ...state,
        tasks: {
          ...state.tasks,
          [event.taskId]: {
            ...state.tasks[event.taskId],
            status: 'completed',
            completedAt: event.completedAt
          }
        }
      };
  }
};
```

## Complete Example: Functional Task Entity

```typescript
// Types
type TaskId = string & { readonly __brand: 'TaskId' };
type TaskTitle = string & { readonly __brand: 'TaskTitle' };

type TaskStatus = 'pending' | 'completed';

type Task = {
  readonly id: TaskId;
  readonly title: TaskTitle;
  readonly status: TaskStatus;
  readonly createdAt: Date;
  readonly completedAt: Date | null;
};

// Smart constructors
const createTaskId = (): TaskId => crypto.randomUUID() as TaskId;

const createTaskTitle = (input: string): Result<TaskTitle, ValidationError> => {
  const trimmed = input.trim();

  if (trimmed.length === 0) {
    return Err(new ValidationError('Title cannot be empty'));
  }

  if (trimmed.length > 200) {
    return Err(new ValidationError('Title too long'));
  }

  return Ok(trimmed as TaskTitle);
};

// Factory
const createTask = (title: TaskTitle): Task => ({
  id: createTaskId(),
  title,
  status: 'pending',
  createdAt: new Date(),
  completedAt: null
});

// Domain operations (pure functions)
const completeTask = (task: Task): Result<Task, DomainError> => {
  if (task.status === 'completed') {
    return Err(new DomainError('Task already completed'));
  }

  return Ok({
    ...task,
    status: 'completed',
    completedAt: new Date()
  });
};

const reopenTask = (task: Task): Result<Task, DomainError> => {
  if (task.status === 'pending') {
    return Err(new DomainError('Task already pending'));
  }

  return Ok({
    ...task,
    status: 'pending',
    completedAt: null
  });
};

// Composition
const createAndCompleteTask = (titleInput: string): Result<Task, Error> => {
  return flatMap(
    createTaskTitle(titleInput),
    (title) => {
      const task = createTask(title);
      return completeTask(task);
    }
  );
};

// Usage
const result = createAndCompleteTask('Buy milk');

if (result.ok) {
  const task = result.value;
  console.log(`Created task ${task.id} with status ${task.status}`);
} else {
  console.error(result.error.message);
}
```

## Benefits of Functional DDD

1. **Type Safety**: Compile-time guarantees of correctness
2. **Testability**: Pure functions are easy to test
3. **Immutability**: No unexpected side effects
4. **Composition**: Build complex behavior from simple functions
5. **Referential Transparency**: Same inputs always produce same outputs
6. **Concurrency**: Immutable data is thread-safe

## Trade-offs

| Aspect | Functional DDD | Traditional OOP DDD |
|--------|----------------|---------------------|
| **Learning Curve** | Steeper | Gentler |
| **Verbosity** | More type annotations | More classes/methods |
| **Performance** | Good (immutable structures) | Good (mutable when needed) |
| **Debugging** | Easier (pure functions) | Harder (side effects) |
| **Team Familiarity** | Less common | More common |

## Recommended Libraries

```typescript
// fp-ts: Functional programming library
import { Either, left, right } from 'fp-ts/Either';
import { pipe } from 'fp-ts/function';

const createUser = (email: string): Either<Error, User> => {
  return pipe(
    validateEmail(email),
    Either.chain(checkNotTaken),
    Either.map(createUserEntity)
  );
};

// io-ts: Runtime type validation
import * as t from 'io-ts';

const UserCodec = t.type({
  id: t.string,
  email: t.string,
  name: t.string
});

type User = t.TypeOf<typeof UserCodec>;

// zod: Schema validation
import { z } from 'zod';

const TaskSchema = z.object({
  id: z.string().uuid(),
  title: z.string().min(1).max(200),
  status: z.enum(['pending', 'completed'])
});

type Task = z.infer<typeof TaskSchema>;
```

---

See also:
- `aggregates.md` - Aggregate design patterns
- `../examples/task-app/` - OOP-style example for comparison
