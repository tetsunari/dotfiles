/**
 * TaskId Value Object
 *
 * Represents a unique identifier for a Task.
 * Immutable and validates format.
 */
export class TaskId {
  private readonly _brand: 'TaskId' = 'TaskId'; // Nominal typing
  private readonly value: string;

  private constructor(id: string) {
    this.value = id;
  }

  /**
   * Create a new TaskId with generated UUID
   */
  static create(): TaskId {
    // In browser environment, use crypto.randomUUID()
    // In Node.js < 19, you might need 'uuid' package
    const uuid = crypto.randomUUID();
    return new TaskId(uuid);
  }

  /**
   * Create TaskId from existing string (e.g., from database)
   * @param id - UUID string
   * @throws Error if format is invalid
   */
  static fromString(id: string): TaskId {
    if (!TaskId.isValidUUID(id)) {
      throw new Error(`Invalid TaskId format: ${id}`);
    }

    return new TaskId(id);
  }

  /**
   * Validate UUID format
   */
  private static isValidUUID(uuid: string): boolean {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    return uuidRegex.test(uuid);
  }

  /**
   * Get string representation
   */
  toString(): string {
    return this.value;
  }

  /**
   * Value Object equality (compare by value, not reference)
   */
  equals(other: TaskId): boolean {
    if (!other) {
      return false;
    }

    return this.value === other.value;
  }

  /**
   * Get raw value (use sparingly, prefer toString())
   */
  getValue(): string {
    return this.value;
  }
}
