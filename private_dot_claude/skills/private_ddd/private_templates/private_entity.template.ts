/**
 * [EntityName] Entity Template
 *
 * Replace [EntityName] with your entity name (e.g., User, Order, Product)
 * Replace [EntityId] with your ID value object (e.g., UserId, OrderId)
 */

import { [EntityId] } from './[entity-id].value-object';

export class [EntityName] {
  private constructor(
    private readonly id: [EntityId],
    // Add other properties here
    // private propertyName: PropertyType,
    private readonly createdAt: Date,
    private updatedAt: Date
  ) {}

  /**
   * Factory method to create new entity
   * Add parameters as needed
   */
  static create(/* parameters */): [EntityName] {
    // Validation logic
    // if (!isValid) {
    //   throw new Error('Validation message');
    // }

    return new [EntityName](
      [EntityId].create(),
      // Initialize properties
      new Date(),
      new Date()
    );
  }

  /**
   * Reconstruct entity from persistence
   * Used by repository to recreate domain object
   */
  static reconstruct(
    id: string,
    // Add stored properties
    createdAt: Date,
    updatedAt: Date
  ): [EntityName] {
    return new [EntityName](
      [EntityId].fromString(id),
      // Map properties
      createdAt,
      updatedAt
    );
  }

  /**
   * Domain behavior methods
   * Add methods that represent business actions
   */
  // doSomething(): void {
  //   // Domain logic with validation
  //   // Update state
  //   this.updatedAt = new Date();
  // }

  // Getters (expose immutable state)
  getId(): [EntityId] {
    return this.id;
  }

  getCreatedAt(): Date {
    return this.createdAt;
  }

  getUpdatedAt(): Date {
    return this.updatedAt;
  }

  /**
   * Entity equality based on identity (ID)
   */
  equals(other: [EntityName]): boolean {
    if (!other) {
      return false;
    }

    return this.id.equals(other.id);
  }
}
