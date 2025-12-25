/**
 * TaskStatus Value Object
 *
 * Represents the status of a task (pending or completed).
 * Immutable and type-safe.
 */
export type TaskStatusType = 'pending' | 'completed';

export class TaskStatus {
  private readonly _brand: 'TaskStatus' = 'TaskStatus';
  private readonly value: TaskStatusType;

  private constructor(status: TaskStatusType) {
    this.value = status;
  }

  /**
   * Create a pending status
   */
  static pending(): TaskStatus {
    return new TaskStatus('pending');
  }

  /**
   * Create a completed status
   */
  static completed(): TaskStatus {
    return new TaskStatus('completed');
  }

  /**
   * Create from string (e.g., from database)
   * @param status - Status string
   * @throws Error if status is invalid
   */
  static fromString(status: string): TaskStatus {
    if (status !== 'pending' && status !== 'completed') {
      throw new Error(`Invalid task status: ${status}`);
    }

    return new TaskStatus(status);
  }

  /**
   * Check if status is pending
   */
  isPending(): boolean {
    return this.value === 'pending';
  }

  /**
   * Check if status is completed
   */
  isCompleted(): boolean {
    return this.value === 'completed';
  }

  /**
   * Get string representation
   */
  toString(): TaskStatusType {
    return this.value;
  }

  /**
   * Value Object equality
   */
  equals(other: TaskStatus): boolean {
    if (!other) {
      return false;
    }

    return this.value === other.value;
  }

  /**
   * Get raw value
   */
  getValue(): TaskStatusType {
    return this.value;
  }
}
