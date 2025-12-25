import { Task } from './task.entity';
import { TaskId } from './task-id.value-object';

/**
 * Task Repository Interface (Port)
 *
 * Defines the contract for task persistence.
 * Implementation is in the infrastructure layer.
 */
export interface TaskRepository {
  /**
   * Save a task (create or update)
   * @param task - Task entity to persist
   */
  save(task: Task): Promise<void>;

  /**
   * Find task by ID
   * @param id - Task identifier
   * @returns Task if found, null otherwise
   */
  findById(id: TaskId): Promise<Task | null>;

  /**
   * Find all tasks
   * @returns Array of all tasks
   */
  findAll(): Promise<Task[]>;

  /**
   * Find tasks by status
   * @param status - 'pending' or 'completed'
   * @returns Array of tasks with specified status
   */
  findByStatus(status: 'pending' | 'completed'): Promise<Task[]>;

  /**
   * Delete a task
   * @param id - Task identifier
   */
  delete(id: TaskId): Promise<void>;

  /**
   * Check if task exists
   * @param id - Task identifier
   * @returns true if task exists
   */
  exists(id: TaskId): Promise<boolean>;
}
