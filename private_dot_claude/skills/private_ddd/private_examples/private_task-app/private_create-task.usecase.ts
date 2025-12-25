import { Task } from './task.entity';
import { TaskRepository } from './task.repository';

/**
 * Create Task Use Case Request DTO
 */
export interface CreateTaskRequest {
  title: string;
}

/**
 * Create Task Use Case Response DTO
 */
export interface CreateTaskResponse {
  id: string;
  title: string;
  status: string;
  createdAt: string;
}

/**
 * Create Task Use Case
 *
 * Application service that orchestrates task creation.
 * Follows the single responsibility principle.
 */
export class CreateTaskUseCase {
  constructor(private readonly taskRepository: TaskRepository) {}

  async execute(request: CreateTaskRequest): Promise<CreateTaskResponse> {
    // 1. Create domain entity (validation happens here)
    const task = Task.create(request.title);

    // 2. Persist using repository
    await this.taskRepository.save(task);

    // 3. Convert to DTO and return
    return this.toResponse(task);
  }

  /**
   * Map domain entity to response DTO
   * Keeps domain model separate from presentation
   */
  private toResponse(task: Task): CreateTaskResponse {
    return {
      id: task.getId().toString(),
      title: task.getTitle(),
      status: task.getStatus().toString(),
      createdAt: task.getCreatedAt().toISOString(),
    };
  }
}
