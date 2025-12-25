import { Task } from './task.entity';
import { TaskId } from './task-id.value-object';
import { TaskRepository } from './task.repository';

/**
 * In-Memory Task Repository Implementation
 *
 * Simple implementation for testing or prototyping.
 * In production, replace with DynamoDB/PostgreSQL implementation.
 */
export class InMemoryTaskRepository implements TaskRepository {
  private tasks: Map<string, Task> = new Map();

  async save(task: Task): Promise<void> {
    // Store by ID
    this.tasks.set(task.getId().toString(), task);
  }

  async findById(id: TaskId): Promise<Task | null> {
    const task = this.tasks.get(id.toString());
    return task || null;
  }

  async findAll(): Promise<Task[]> {
    return Array.from(this.tasks.values());
  }

  async findByStatus(status: 'pending' | 'completed'): Promise<Task[]> {
    return Array.from(this.tasks.values()).filter((task) =>
      task.getStatus().toString() === status
    );
  }

  async delete(id: TaskId): Promise<void> {
    this.tasks.delete(id.toString());
  }

  async exists(id: TaskId): Promise<boolean> {
    return this.tasks.has(id.toString());
  }

  /**
   * Clear all tasks (useful for testing)
   */
  async clear(): Promise<void> {
    this.tasks.clear();
  }
}
