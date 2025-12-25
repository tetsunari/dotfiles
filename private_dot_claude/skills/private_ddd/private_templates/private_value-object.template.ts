/**
 * [ValueObjectName] Value Object Template
 *
 * Replace [ValueObjectName] with your value object name
 * Examples: Email, PhoneNumber, Money, Address
 */

export class [ValueObjectName] {
  private readonly _brand: '[ValueObjectName]' = '[ValueObjectName]';
  private readonly value: [ValueType]; // Replace [ValueType] with actual type

  private constructor(value: [ValueType]) {
    this.value = value;
  }

  /**
   * Smart constructor with validation
   * @param value - Input value
   * @returns Value object instance
   * @throws Error if validation fails
   */
  static create(value: [ValueType]): [ValueObjectName] {
    // Validation logic
    if (!this.isValid(value)) {
      throw new Error('Invalid [ValueObjectName]');
    }

    return new [ValueObjectName](value);
  }

  /**
   * Create from string (for simple value objects)
   * Remove if not needed
   */
  static fromString(str: string): [ValueObjectName] {
    // Parse and validate
    // const parsed = parseValue(str);
    return this.create(/* parsed value */);
  }

  /**
   * Validation logic
   * @param value - Value to validate
   * @returns true if valid
   */
  private static isValid(value: [ValueType]): boolean {
    // Add validation rules
    // Example for email:
    // return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
    return true;
  }

  /**
   * Get string representation
   */
  toString(): string {
    return String(this.value);
  }

  /**
   * Value Object equality (compare by value)
   */
  equals(other: [ValueObjectName]): boolean {
    if (!other) {
      return false;
    }

    return this.value === other.value;
  }

  /**
   * Get raw value (use sparingly)
   */
  getValue(): [ValueType] {
    return this.value;
  }
}
