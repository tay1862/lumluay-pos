import { Injectable } from '@nestjs/common';
import { eq, and, desc } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  async findForUser(tenantId: string, userId: string, unreadOnly = false) {
    const conditions = [
      eq(schema.notifications.tenantId, tenantId),
      eq(schema.notifications.userId, userId),
    ];

    if (unreadOnly) conditions.push(eq(schema.notifications.isRead, false));

    return this.db
      .select()
      .from(schema.notifications)
      .where(and(...conditions))
      .orderBy(desc(schema.notifications.createdAt))
      .limit(50);
  }

  async markRead(tenantId: string, userId: string, id: string) {
    const [notif] = await this.db
      .update(schema.notifications)
      .set({ isRead: true, readAt: new Date() })
      .where(
        and(
          eq(schema.notifications.tenantId, tenantId),
          eq(schema.notifications.userId, userId),
          eq(schema.notifications.id, id),
        ),
      )
      .returning();

    return notif;
  }

  async markAllRead(tenantId: string, userId: string) {
    await this.db
      .update(schema.notifications)
      .set({ isRead: true, readAt: new Date() })
      .where(
        and(
          eq(schema.notifications.tenantId, tenantId),
          eq(schema.notifications.userId, userId),
          eq(schema.notifications.isRead, false),
        ),
      );

    return { updated: true };
  }

  async create(
    tenantId: string,
    data: {
      userId?: string;
      type: string;
      title: string;
      body?: string;
      data?: Record<string, unknown>;
    },
  ) {
    const [notif] = await this.db
      .insert(schema.notifications)
      .values({
        tenantId,
        userId: data.userId,
        type: data.type,
        title: data.title,
        body: data.body,
        data: data.data ?? {},
      })
      .returning();

    return notif;
  }

  async getUnreadCount(tenantId: string, userId: string) {
    const results = await this.db
      .select({ id: schema.notifications.id })
      .from(schema.notifications)
      .where(
        and(
          eq(schema.notifications.tenantId, tenantId),
          eq(schema.notifications.userId, userId),
          eq(schema.notifications.isRead, false),
        ),
      );

    return { count: results.length };
  }
}
