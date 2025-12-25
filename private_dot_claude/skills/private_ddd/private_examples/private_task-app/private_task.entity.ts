import { TaskId } from './task-id.value-object';
import { TaskStatus } from './task-status.value-object';

/**
 * Task Entity (Aggregate Root)
 *
 * Represents a task in the task management system.
 * Contains business logic for task lifecycle management.
 */
export class Task {
  private constructor(
    private readonly id: TaskId,
    private title: string,
    private status: TaskStatus,
    private readonly createdAt: Date,
    private completedAt: Date | null = null
  ) {}

  /**
   * Factory method to create a new task
   * @param title - Task title (must not be empty)
   * @returns New Task instance
   * @throws Error if title is invalid
   */
  static create(title: string): Task {
    // Domain validation
    if (!title || title.trim().length === 0) {
      throw new Error('Task title is required');
    }

    if (title.length > 200) {
      throw new Error('Task title must not exceed 200 characters');
    }

    return new Task(
      TaskId.create(),
      title.trim(),
      TaskStatus.pending(),
      new Date(),
      null
    );
  }

  /**
   * Reconstruct task from persistence
   * Used by repository to recreate entity from stored data
   */
  static reconstruct(
    id: string,
    title: string,
    status: 'pending' | 'completed',
    createdAt: Date,
    completedAt: Date | null
  ): Task {
    return new Task(
      TaskId.fromString(id),
      title,
      status === 'completed' ? TaskStatus.completed() : TaskStatus.pending(),
      createdAt,
      completedAt
    );
  }

  /**
   * Complete the task
   * Domain logic: Can only complete pending tasks
   * @throws Error if task is already completed
   */
  complete(): void {
    if (this.status.isCompleted()) {
      throw new Error('Task is already completed');
    }

    this.status = TaskStatus.completed();
    this.completedAt = new Date();
  }

  /**
   * Reopen a completed task
   * @throws Error if task is not completed
   */
  reopen(): void {
    if (!this.status.isCompleted()) {
      throw new Error('Only completed tasks can be reopened');
    }

    this.status = TaskStatus.pending();
    this.completedAt = null;
  }

  /**
   * Update task title
   * @param newTitle - New title for the task
   * @throws Error if new title is invalid
   */
  updateTitle(newTitle: string): void {
    if (!newTitle || newTitle.trim().length === 0) {
      throw new Error('Task title is required');
    }

    if (newTitle.length > 200) {
      throw new Error('Task title must not exceed 200 characters');
    }

    this.title = newTitle.trim();
  }

  /**
   * Check if task is overdue (example business logic)
   * @param currentDate - Current date to check against
   * @returns true if task is overdue (pending for more than 7 days)
   */
  isOverdue(currentDate: Date = new Date()): boolean {
    if (this.status.isCompleted()) {
      return false;
    }

    const daysSinceCreation = Math.floor(
      (currentDate.getTime() - this.createdAt.getTime()) / (1000 * 60 * 60 * 24)
    );

    return daysSinceCreation > 7;
  }

  // Getters (expose immutable state)
  getId(): TaskId {
    return this.id;
  }

  getTitle(): string {
    return this.title;
  }

  getStatus(): TaskStatus {
    return this.status;
  }

  getCreatedAt(): Date {
    return this.createdAt;
  }

  getCompletedAt(): Date | null {
    return this.completedAt;
  }

  /**
   * Check equality based on identity (ID)
   */
  equals(other: Task): boolean {
    if (!other) {
      return false;
    }

    return this.id.equals(other.id);
  }
}
