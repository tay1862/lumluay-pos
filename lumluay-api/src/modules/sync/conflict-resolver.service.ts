import { Injectable, Logger } from '@nestjs/common';
import { eq, and } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';
import { SyncOperationDto } from './dto/sync.dto';

export type ConflictResolution = 'applied' | 'skipped' | 'error';

export interface OperationResult {
  clientTimestamp: string;
  status: ConflictResolution;
  error?: string;
}

/**
 * 16.1.2 / 16.1.3 — Conflict Resolver Service
 *
 * Strategy: last-write-wins based on clientTimestamp.
 * Supported entity types: product, category, member
 */
@Injectable()
export class ConflictResolverService {
  private readonly logger = new Logger(ConflictResolverService.name);

  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  async resolveOperation(
    tenantId: string,
    op: SyncOperationDto,
  ): Promise<OperationResult> {
    try {
      switch (op.entityType) {
        case 'product':
          await this.resolveProduct(tenantId, op);
          break;
        case 'category':
          await this.resolveCategory(tenantId, op);
          break;
        case 'member':
          await this.resolveMember(tenantId, op);
          break;
        default:
          // Unknown entity types are queued but not applied
          this.logger.warn(`Unknown entityType: ${op.entityType} — queued only`);
      }
      return { clientTimestamp: op.clientTimestamp, status: 'applied' };
    } catch (err: unknown) {
      this.logger.error(
        `Failed to resolve op for ${op.entityType}/${op.entityId}: ${err}`,
      );
      return {
        clientTimestamp: op.clientTimestamp,
        status: 'error',
        error: err instanceof Error ? err.message : 'Unknown error',
      };
    }
  }

  // ─── Products ─────────────────────────────────────────────────────────────

  private async resolveProduct(tenantId: string, op: SyncOperationDto) {
    const payload = op.payload as Record<string, unknown>;

    if (op.operation === 'delete' && op.entityId) {
      await this.db
        .update(schema.products)
        .set({ isActive: false, updatedAt: new Date() })
        .where(
          and(
            eq(schema.products.tenantId, tenantId),
            eq(schema.products.id, op.entityId),
          ),
        );
      return;
    }

    if (op.operation === 'update' && op.entityId) {
      // Last-write-wins: only update if the record hasn't been modified after clientTimestamp
      const clientTs = new Date(op.clientTimestamp);
      const [existing] = await this.db
        .select({ updatedAt: schema.products.updatedAt })
        .from(schema.products)
        .where(
          and(
            eq(schema.products.tenantId, tenantId),
            eq(schema.products.id, op.entityId),
          ),
        )
        .limit(1);

      if (existing && existing.updatedAt && existing.updatedAt > clientTs) {
        this.logger.debug(
          `Skipping stale update for product ${op.entityId}: server is newer`,
        );
        return;
      }

      await this.db
        .update(schema.products)
        .set({
          ...(payload.name !== undefined && { name: payload.name as string }),
          ...(payload.basePrice !== undefined && { basePrice: String(payload.basePrice) }),
          ...(payload.isActive !== undefined && { isActive: payload.isActive as boolean }),
          ...(payload.trackStock !== undefined && { trackStock: payload.trackStock as boolean }),
          updatedAt: new Date(),
        })
        .where(
          and(
            eq(schema.products.tenantId, tenantId),
            eq(schema.products.id, op.entityId),
          ),
        );
      return;
    }

    if (op.operation === 'create') {
      // Upsert — ignore if already exists
      await this.db
        .insert(schema.products)
        .values({
          id: op.entityId,
          tenantId,
          name: (payload.name as string) ?? 'Unknown',
          basePrice: String(payload.basePrice ?? 0),
          isActive: (payload.isActive as boolean) ?? true,
        })
        .onConflictDoNothing();
    }
  }

  // ─── Categories ───────────────────────────────────────────────────────────

  private async resolveCategory(tenantId: string, op: SyncOperationDto) {
    const payload = op.payload as Record<string, unknown>;

    if (op.operation === 'delete' && op.entityId) {
      await this.db
        .update(schema.categories)
        .set({ isActive: false, updatedAt: new Date() })
        .where(
          and(
            eq(schema.categories.tenantId, tenantId),
            eq(schema.categories.id, op.entityId),
          ),
        );
      return;
    }

    if (op.operation === 'update' && op.entityId) {
      await this.db
        .update(schema.categories)
        .set({
          ...(payload.name !== undefined && { name: payload.name as string }),
          ...(payload.isActive !== undefined && { isActive: payload.isActive as boolean }),
          updatedAt: new Date(),
        })
        .where(
          and(
            eq(schema.categories.tenantId, tenantId),
            eq(schema.categories.id, op.entityId),
          ),
        );
      return;
    }

    if (op.operation === 'create') {
      await this.db
        .insert(schema.categories)
        .values({
          id: op.entityId,
          tenantId,
          name: (payload.name as string) ?? 'Unknown',
          isActive: (payload.isActive as boolean) ?? true,
        })
        .onConflictDoNothing();
    }
  }

  // ─── Members ──────────────────────────────────────────────────────────────

  private async resolveMember(tenantId: string, op: SyncOperationDto) {
    const payload = op.payload as Record<string, unknown>;

    if (op.operation === 'update' && op.entityId) {
      await this.db
        .update(schema.members)
        .set({
          ...(payload.name !== undefined && { name: payload.name as string }),
          ...(payload.phone !== undefined && { phone: payload.phone as string }),
          ...(payload.points !== undefined && { points: payload.points as number }),
          updatedAt: new Date(),
        })
        .where(
          and(
            eq(schema.members.tenantId, tenantId),
            eq(schema.members.id, op.entityId),
          ),
        );
      return;
    }

    if (op.operation === 'create') {
      await this.db
        .insert(schema.members)
        .values({
          id: op.entityId,
          tenantId,
          name: (payload.name as string) ?? 'Unknown',
          phone: payload.phone as string,
          points: (payload.points as number) ?? 0,
        })
        .onConflictDoNothing();
    }
  }
}
