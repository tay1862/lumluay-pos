import { Injectable } from '@nestjs/common';
import { eq, and, gte } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';
import { PushSyncDto, PullSyncDto } from './dto/sync.dto';
import { ConflictResolverService } from './conflict-resolver.service';

@Injectable()
export class SyncService {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
    private readonly conflictResolver: ConflictResolverService,
  ) {}

  /**
   * 16.1.4 Pull: return changed entities since the given timestamp so the device
   * can keep its local cache up to date. Returns products, categories, and members
   * that were updated/created after `since`.
   */
  async pull(tenantId: string, userId: string, dto: PullSyncDto) {
    const since = dto.since ? new Date(dto.since) : new Date(0);

    const [products, categories, members] = await Promise.all([
      this.db
        .select()
        .from(schema.products)
        .where(
          and(eq(schema.products.tenantId, tenantId), gte(schema.products.updatedAt, since)),
        )
        .orderBy(schema.products.updatedAt)
        .limit(500),

      this.db
        .select()
        .from(schema.categories)
        .where(
          and(
            eq(schema.categories.tenantId, tenantId),
            gte(schema.categories.updatedAt, since),
          ),
        )
        .orderBy(schema.categories.updatedAt),

      this.db
        .select()
        .from(schema.members)
        .where(
          and(eq(schema.members.tenantId, tenantId), gte(schema.members.updatedAt, since)),
        )
        .orderBy(schema.members.updatedAt)
        .limit(500),
    ]);

    return {
      deviceId: dto.deviceId,
      serverTime: new Date().toISOString(),
      since: since.toISOString(),
      data: { products, categories, members },
    };
  }

  /**
   * 16.1.2 / 16.1.3 Push: accept batched operations from an offline device.
   * Operations are queued AND immediately applied via ConflictResolverService
   * using last-write-wins conflict resolution.
   */
  async push(tenantId: string, userId: string, dto: PushSyncDto) {
    const results: { clientTimestamp: string; status: string; error?: string }[] = [];

    for (const op of dto.operations) {
      // 1. Always queue the operation for audit / acknowledgement tracking
      try {
        await this.db.insert(schema.syncQueue).values({
          tenantId,
          deviceId: dto.deviceId,
          userId,
          operation: op.operation,
          entityType: op.entityType,
          entityId: op.entityId,
          payload: op.payload,
          checksum: op.checksum,
          isSynced: false,
        });
      } catch {
        // If already queued (duplicate), continue to conflict resolution
      }

      // 2. Apply with conflict resolution
      const result = await this.conflictResolver.resolveOperation(tenantId, op);
      results.push({
        clientTimestamp: result.clientTimestamp,
        status: result.status,
        error: result.error,
      });
    }

    return {
      deviceId: dto.deviceId,
      serverTime: new Date().toISOString(),
      results,
    };
  }

  /**
   * Acknowledge: mark sync items as successfully processed by the device.
   */
  async acknowledge(tenantId: string, ids: string[]) {
    for (const id of ids) {
      await this.db
        .update(schema.syncQueue)
        .set({ isSynced: true, syncedAt: new Date() })
        .where(
          and(eq(schema.syncQueue.tenantId, tenantId), eq(schema.syncQueue.id, id)),
        );
    }
    return { acknowledged: ids.length };
  }

  async getStatus(tenantId: string, deviceId: string) {
    const all = await this.db
      .select()
      .from(schema.syncQueue)
      .where(
        and(
          eq(schema.syncQueue.tenantId, tenantId),
          eq(schema.syncQueue.deviceId, deviceId),
          eq(schema.syncQueue.isSynced, false),
        ),
      );

    return {
      deviceId,
      pendingCount: all.length,
      serverTime: new Date().toISOString(),
    };
  }
}
