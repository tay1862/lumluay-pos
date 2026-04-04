import { Injectable, NotFoundException } from '@nestjs/common';
import { eq, and, desc, count, sql } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';
import { CreateQueueEntryDto, UpdateQueueStatusDto } from './dto/queue.dto';

@Injectable()
export class QueueService {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  async findActive(tenantId: string) {
    return this.db
      .select()
      .from(schema.queue)
      .where(
        and(
          eq(schema.queue.tenantId, tenantId),
          sql`${schema.queue.status} IN ('waiting', 'called')`,
        ),
      )
      .orderBy(schema.queue.createdAt);
  }

  async findAll(tenantId: string, date?: string) {
    const filterDate = date ? new Date(date) : new Date();
    const start = new Date(filterDate);
    start.setHours(0, 0, 0, 0);
    const end = new Date(filterDate);
    end.setHours(23, 59, 59, 999);

    return this.db
      .select()
      .from(schema.queue)
      .where(
        and(
          eq(schema.queue.tenantId, tenantId),
          sql`${schema.queue.createdAt} BETWEEN ${start} AND ${end}`,
        ),
      )
      .orderBy(schema.queue.createdAt);
  }

  async findOne(tenantId: string, id: string) {
    const [entry] = await this.db
      .select()
      .from(schema.queue)
      .where(and(eq(schema.queue.tenantId, tenantId), eq(schema.queue.id, id)));

    if (!entry) throw new NotFoundException(`Queue entry ${id} not found`);
    return entry;
  }

  async create(tenantId: string, dto: CreateQueueEntryDto) {
    const ticketNumber = await this.generateTicket(tenantId);

    const [entry] = await this.db
      .insert(schema.queue)
      .values({
        tenantId,
        name: dto.name,
        phone: dto.phone,
        guestCount: dto.guestCount,
        note: dto.note,
        memberId: dto.memberId,
        ticketNumber,
        status: 'waiting',
      })
      .returning();

    return entry;
  }

  async updateStatus(tenantId: string, id: string, dto: UpdateQueueStatusDto) {
    await this.findOne(tenantId, id);

    const now = new Date();
    const updates: Record<string, unknown> = {
      status: dto.status,
      updatedAt: now,
    };

    if (dto.status === 'called') updates.calledAt = now;
    if (dto.status === 'seated') {
      updates.seatedAt = now;
      if (dto.orderId) updates.orderId = dto.orderId;
    }
    if (dto.estimatedWaitMinutes != null)
      updates.estimatedWaitMinutes = dto.estimatedWaitMinutes;

    const [entry] = await this.db
      .update(schema.queue)
      .set(updates)
      .where(and(eq(schema.queue.tenantId, tenantId), eq(schema.queue.id, id)))
      .returning();

    return entry;
  }

  async getStats(tenantId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [stats] = await this.db
      .select({
        waiting: count(
          sql`CASE WHEN ${schema.queue.status} = 'waiting' THEN 1 END`,
        ),
        called: count(
          sql`CASE WHEN ${schema.queue.status} = 'called' THEN 1 END`,
        ),
        seated: count(
          sql`CASE WHEN ${schema.queue.status} = 'seated' THEN 1 END`,
        ),
        totalToday: count(schema.queue.id),
      })
      .from(schema.queue)
      .where(
        and(
          eq(schema.queue.tenantId, tenantId),
          sql`${schema.queue.createdAt} >= ${today}`,
        ),
      );

    return stats;
  }

  private async generateTicket(tenantId: string): Promise<string> {
    const [{ count: todayCount }] = await this.db
      .select({ count: count(schema.queue.id) })
      .from(schema.queue)
      .where(
        and(
          eq(schema.queue.tenantId, tenantId),
          sql`${schema.queue.createdAt} >= CURRENT_DATE`,
        ),
      );

    const num = Number(todayCount) + 1;
    return `Q${String(num).padStart(3, '0')}`;
  }
}
