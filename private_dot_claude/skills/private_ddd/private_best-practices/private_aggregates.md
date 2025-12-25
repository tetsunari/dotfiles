# Aggregate Design Best Practices

## What is an Aggregate?

An **aggregate** is a cluster of domain objects (entities and value objects) that are treated as a single unit for data consistency. Each aggregate has a root entity called the **Aggregate Root**, which is the only entry point for modifying the aggregate.

## Core Principles

### 1. Consistency Boundary

Aggregates define **transactional consistency boundaries**.

```typescript
// ✅ Good: Order is the aggregate root
class Order {
  private items: OrderItem[] = [];
  private status: OrderStatus;

  addItem(product: Product, quantity: number): void {
    // Validate business rules
    if (this.status.isShipped()) {
      throw new Error('Cannot modify shipped order');
    }

    // Ensure consistency
    const item = OrderItem.create(product, quantity);
    this.items.push(item);
    this.recalculateTotal();  // Keep aggregate consistent
  }
}

// OrderItem cannot be modified directly
class OrderItem {
  // No public setters - immutable within aggregate
}
```

### 2. Small Aggregates

**Keep aggregates as small as possible** to avoid:
- Performance issues (loading large object graphs)
- Concurrency conflicts (many users modifying same aggregate)
- Complexity in maintaining invariants

```typescript
// ❌ Bad: Aggregate too large
class Customer {
  private orders: Order[] = [];      // All orders!
  private addresses: Address[] = [];
  private paymentMethods: PaymentMethod[] = [];
  private preferences: Preferences;
  // ...
}

// ✅ Good: Separate aggregates
class Customer {
  private primaryAddress: Address;   // Only essential data
  private email: Email;
}

class Order {
  private customerId: CustomerId;    // Reference by ID
  private items: OrderItem[];
}
```

### 3. Reference by Identity

Aggregates should reference other aggregates **by ID**, not by object reference.

```typescript
// ❌ Bad: Direct object reference
class Order {
  private customer: Customer;  // Loads entire Customer aggregate
}

// ✅ Good: Reference by ID
class Order {
  private customerId: CustomerId;  // Just the ID
}

// Load customer separately when needed
const customer = await customerRepository.findById(order.getCustomerId());
```

### 4. One Repository Per Aggregate

Each aggregate root should have its own repository.

```typescript
// ✅ Good: One repository per aggregate root
interface OrderRepository {
  save(order: Order): Promise<void>;
  findById(id: OrderId): Promise<Order | null>;
}

interface CustomerRepository {
  save(customer: Customer): Promise<void>;
  findById(id: CustomerId): Promise<Customer | null>;
}

// ❌ Bad: Repository for child entity
interface OrderItemRepository {  // OrderItem is part of Order aggregate
  save(item: OrderItem): Promise<void>;  // Should not exist!
}
```

### 5. Enforce Invariants

The aggregate root must enforce all business rules within its boundary.

```typescript
class ShoppingCart {
  private items: CartItem[] = [];
  private readonly maxItems = 50;

  addItem(product: Product, quantity: number): void {
    // Enforce invariant: max 50 items
    if (this.items.length >= this.maxItems) {
      throw new Error('Cart cannot exceed 50 items');
    }

    // Enforce invariant: quantity > 0
    if (quantity <= 0) {
      throw new Error('Quantity must be positive');
    }

    // Enforce invariant: no duplicate products
    if (this.hasProduct(product.getId())) {
      throw new Error('Product already in cart');
    }

    this.items.push(CartItem.create(product, quantity));
  }

  private hasProduct(productId: ProductId): boolean {
    return this.items.some(item => item.getProductId().equals(productId));
  }
}
```

## Identifying Aggregate Boundaries

### Questions to Ask

1. **What must be consistent together?**
   - If data must change together atomically → same aggregate
   - If eventual consistency is OK → separate aggregates

2. **What is the unit of change?**
   - Operations that always happen together → same aggregate
   - Independent operations → separate aggregates

3. **What are the transactional boundaries?**
   - Must succeed/fail together → same aggregate
   - Can fail independently → separate aggregates

### Example: E-Commerce

```typescript
// Aggregate 1: Order (consistency boundary)
class Order {
  private id: OrderId;
  private customerId: CustomerId;      // Reference by ID
  private items: OrderItem[];          // Part of aggregate
  private shippingAddress: Address;    // Part of aggregate
  private status: OrderStatus;

  // All order items must be consistent with order
  addItem(product: Product, quantity: number): void {
    if (this.status.isShipped()) {
      throw new Error('Cannot modify shipped order');
    }
    this.items.push(OrderItem.create(product, quantity));
    this.recalculateTotal();
  }
}

// Aggregate 2: Customer (separate consistency boundary)
class Customer {
  private id: CustomerId;
  private email: Email;
  private defaultAddress: Address;
  // No orders array - reference by ID instead
}

// Aggregate 3: Product (separate consistency boundary)
class Product {
  private id: ProductId;
  private name: string;
  private price: Money;
  // No order items - reference by ID instead
}
```

## Common Patterns

### Pattern 1: Aggregate with Multiple Entities

```typescript
// Order is the root, OrderItem is child entity
class Order {
  private items: Map<ProductId, OrderItem> = new Map();

  addItem(productId: ProductId, quantity: number, price: Money): void {
    if (this.items.has(productId)) {
      // Update existing item
      const item = this.items.get(productId)!;
      item.increaseQuantity(quantity);
    } else {
      // Add new item
      const item = OrderItem.create(productId, quantity, price);
      this.items.set(productId, item);
    }
  }

  // External access to items (read-only)
  getItems(): ReadonlyArray<OrderItem> {
    return Array.from(this.items.values());
  }
}

// Child entity - only accessible through Order
class OrderItem {
  private constructor(
    private readonly productId: ProductId,
    private quantity: number,
    private readonly price: Money
  ) {}

  // Package-private: only called by Order
  increaseQuantity(amount: number): void {
    this.quantity += amount;
  }
}
```

### Pattern 2: Aggregate with Value Objects Only

```typescript
// Simple aggregate with no child entities
class Customer {
  private constructor(
    private readonly id: CustomerId,
    private name: PersonName,      // Value object
    private email: Email,          // Value object
    private address: Address       // Value object
  ) {}

  changeEmail(newEmail: Email): void {
    // Value objects are immutable - just replace
    this.email = newEmail;
  }

  relocate(newAddress: Address): void {
    this.address = newAddress;
  }
}
```

### Pattern 3: Event-Sourced Aggregate

```typescript
class Order {
  private uncommittedEvents: DomainEvent[] = [];

  static create(customerId: CustomerId): Order {
    const order = new Order();
    order.apply(new OrderCreated(OrderId.create(), customerId));
    return order;
  }

  addItem(productId: ProductId, quantity: number): void {
    this.apply(new ItemAdded(this.id, productId, quantity));
  }

  private apply(event: DomainEvent): void {
    // Update state based on event
    if (event instanceof OrderCreated) {
      this.id = event.orderId;
      this.customerId = event.customerId;
    } else if (event instanceof ItemAdded) {
      // Add item logic
    }

    this.uncommittedEvents.push(event);
  }

  getUncommittedEvents(): DomainEvent[] {
    return this.uncommittedEvents;
  }
}
```

## Handling Cross-Aggregate Operations

### Strategy 1: Application Service Coordination

```typescript
class PlaceOrderUseCase {
  constructor(
    private orderRepo: OrderRepository,
    private productRepo: ProductRepository,
    private customerRepo: CustomerRepository
  ) {}

  async execute(request: PlaceOrderRequest): Promise<void> {
    // Load aggregates
    const customer = await this.customerRepo.findById(request.customerId);
    const product = await this.productRepo.findById(request.productId);

    // Validate
    if (!customer || !product) {
      throw new Error('Invalid customer or product');
    }

    // Create order (single aggregate operation)
    const order = Order.create(customer.getId());
    order.addItem(product.getId(), request.quantity, product.getPrice());

    // Save
    await this.orderRepo.save(order);
  }
}
```

### Strategy 2: Domain Events (Eventual Consistency)

```typescript
class Order {
  placeOrder(): void {
    this.status = OrderStatus.placed();
    this.addDomainEvent(new OrderPlaced(this.id, this.customerId));
  }
}

// Event handler in separate bounded context
class InventoryEventHandler {
  async handleOrderPlaced(event: OrderPlaced): Promise<void> {
    // Reduce inventory in separate transaction
    const inventory = await this.inventoryRepo.findByProduct(event.productId);
    inventory.reduce(event.quantity);
    await this.inventoryRepo.save(inventory);
  }
}
```

### Strategy 3: Saga Pattern (Long-Running Transactions)

```typescript
class OrderSaga {
  async placeOrder(request: PlaceOrderRequest): Promise<void> {
    try {
      // Step 1: Create order
      const order = await this.createOrder(request);

      // Step 2: Reserve inventory
      await this.reserveInventory(order);

      // Step 3: Process payment
      await this.processPayment(order);

      // Success
      await this.confirmOrder(order);
    } catch (error) {
      // Compensating transactions
      await this.cancelOrder(order);
      await this.releaseInventory(order);
    }
  }
}
```

## Testing Aggregates

```typescript
describe('Order Aggregate', () => {
  it('should enforce maximum items constraint', () => {
    const order = Order.create(customerId);

    // Add 50 items (max)
    for (let i = 0; i < 50; i++) {
      order.addItem(productId, 1, Money.dollars(10));
    }

    // 51st item should fail
    expect(() => {
      order.addItem(productId, 1, Money.dollars(10));
    }).toThrow('Order cannot exceed 50 items');
  });

  it('should not allow modification of shipped orders', () => {
    const order = Order.create(customerId);
    order.addItem(productId, 1, Money.dollars(10));
    order.ship();

    expect(() => {
      order.addItem(anotherProductId, 1, Money.dollars(20));
    }).toThrow('Cannot modify shipped order');
  });
});
```

## Common Mistakes to Avoid

### ❌ Aggregate Too Large
```typescript
// Don't include all related data
class Customer {
  private orders: Order[] = [];  // Could be thousands!
  private invoices: Invoice[] = [];
  private supportTickets: Ticket[] = [];
}
```

### ❌ Modifying Child Directly
```typescript
// Don't expose mutable children
const order = await orderRepo.findById(orderId);
const items = order.getItems();
items.push(newItem);  // Bypasses aggregate root!
```

### ❌ Multiple Aggregates in Transaction
```typescript
// Don't modify multiple aggregates in one transaction
async updateCustomerAndOrder(): Promise<void> {
  const customer = await customerRepo.findById(id);
  const order = await orderRepo.findById(orderId);

  customer.updateEmail(newEmail);  // Aggregate 1
  order.updateAddress(newAddress); // Aggregate 2

  // Both in same transaction - bad!
  await Promise.all([
    customerRepo.save(customer),
    orderRepo.save(order)
  ]);
}
```

### ✅ Use Domain Events Instead
```typescript
// Use eventual consistency via events
customer.updateEmail(newEmail);
await customerRepo.save(customer);
// Event handler will update order asynchronously
```

---

See also:
- `repositories.md` - Repository pattern details
- `../examples/task-app/` - Simple aggregate example
