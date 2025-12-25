/**
 * [UseCaseName] Use Case Template
 *
 * Replace [UseCaseName] with your use case name
 * Examples: CreateUser, PlaceOrder, UpdateProfile
 */

import { [EntityName] } from '../domain/model/[entity-name].entity';
import { [EntityName]Repository } from '../domain/repository/[entity-name].repository';

/**
 * Request DTO for [UseCaseName]
 * Input data structure for the use case
 */
export interface [UseCaseName]Request {
  // Add request fields
  // field: string;
}

/**
 * Response DTO for [UseCaseName]
 * Output data structure returned by the use case
 */
export interface [UseCaseName]Response {
  // Add response fields
  // id: string;
  // status: string;
}

/**
 * [UseCaseName] Use Case
 *
 * Application service that orchestrates domain operations
 * Follows single responsibility principle
 */
export class [UseCaseName]UseCase {
  constructor(
    private readonly [entityName]Repository: [EntityName]Repository
    // Add other dependencies (repositories, services, etc.)
  ) {}

  async execute(request: [UseCaseName]Request): Promise<[UseCaseName]Response> {
    // 1. Input validation (basic format checks)
    this.validate(request);

    // 2. Load domain objects if needed
    // const entity = await this.repository.findById(id);
    // if (!entity) throw new Error('Not found');

    // 3. Execute domain logic
    // const entity = [EntityName].create(...);
    // entity.doSomething(...);

    // 4. Persist changes
    // await this.repository.save(entity);

    // 5. Return response DTO
    return this.toResponse(/* entity */);
  }

  /**
   * Validate request (format-level validation only)
   * Domain validation happens in the domain layer
   */
  private validate(request: [UseCaseName]Request): void {
    // Basic validation
    // if (!request.field) {
    //   throw new Error('Field is required');
    // }
  }

  /**
   * Map domain entity to response DTO
   * Keeps domain model separate from presentation
   */
  private toResponse(/* entity: [EntityName] */): [UseCaseName]Response {
    return {
      // Map fields
      // id: entity.getId().toString(),
    };
  }
}
