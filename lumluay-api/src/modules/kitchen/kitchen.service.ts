import { Injectable, Inject } from '@nestjs/common';
import { eq, and, desc } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import { kitchenTickets } from '@/database/schema';
import { KitchenGateway } from './kitchen.gateway';

@Injectable()
export class KitchenService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
    private readonly kitchenGateway: KitchenGateway,
  ) {}

  findPending(tenantId: string, station?: string) {
    return this.db.query.kitchenTickets.findMany({
      where: and(
        eq(kitchenTickets.tenantId, tenantId),
        eq(kitchenTickets.status, 'pending'),
        station ? eq(kitchenTickets.station, station) : undefined,
      ),
      orderBy: [desc(kitchenTickets.priority), desc(kitchenTickets.createdAt)],
      with: {
        orderItem: {
          with: { order: true, product: true },
        },
      },
    });
  }

  async startPreparing(tenantId: string, id: string) {
    const [updated] = await this.db
      .update(kitchenTickets)
      .set({ status: 'preparing', startedAt: new Date(), updatedAt: new Date() })
      .where(and(eq(kitchenTickets.tenantId, tenantId), eq(kitchenTickets.id, id)))
      .returning();
    if (updated) {
      this.kitchenGateway.emitStatusChanged(tenantId, {
        ticketId: updated.id,
        status: updated.status,
      });
    }
    return updated;
  }

  async markReady(tenantId: string, id: string) {
    const [updated] = await this.db
      .update(kitchenTickets)
      .set({ status: 'ready', readyAt: new Date(), updatedAt: new Date() })
      .where(and(eq(kitchenTickets.tenantId, tenantId), eq(kitchenTickets.id, id)))
      .returning();
    if (updated) {
      this.kitchenGateway.emitStatusChanged(tenantId, {
        ticketId: updated.id,
        status: updated.status,
      });
    }
    return updated;
  }

  async markServed(tenantId: string, id: string) {
    const [updated] = await this.db
      .update(kitchenTickets)
      .set({ status: 'served', updatedAt: new Date() })
      .where(and(eq(kitchenTickets.tenantId, tenantId), eq(kitchenTickets.id, id)))
      .returning();
    if (updated) {
      this.kitchenGateway.emitStatusChanged(tenantId, {
        ticketId: updated.id,
        status: updated.status,
      });
    }
    return updated;
  }
}
