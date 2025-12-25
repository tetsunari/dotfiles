/**
 * [EntityName] Repository Interface Template
 *
 * Replace [EntityName] with your entity name
 * Replace [EntityId] with your ID value object
 */

import { [EntityName] } from '../domain/model/[entity-name].entity';
import { [EntityId] } from '../domain/model/[entity-id].value-object';

/**
 * Repository interface for [EntityName]
 * Defines contract for persistence operations
 * Implementation should be in infrastructure layer
 */
export interface [EntityName]Repository {
  /**
   * Save entity (create or update)
   * @param entity - Entity to persist
   */
  save(entity: [EntityName]): Promise<void>;

  /**
   * Find entity by ID
   * @param id - Entity identifier
   * @returns Entity if found, null otherwise
   */
  findById(id: [EntityId]): Promise<[EntityName] | null>;

  /**
   * Find all entities
   * @returns Array of all entities
   */
  findAll(): Promise<[EntityName][]>;

  /**
   * Delete entity
   * @param id - Entity identifier
   */
  delete(id: [EntityId]): Promise<void>;

  /**
   * Check if entity exists
   * @param id - Entity identifier
   * @returns true if exists
   */
  exists(id: [EntityId]): Promise<boolean>;

  // Add domain-specific query methods as needed
  // findByStatus(status: string): Promise<[EntityName][]>;
  // findByDateRange(start: Date, end: Date): Promise<[EntityName][]>;
}
