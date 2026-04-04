import { Injectable } from '@nestjs/common';
import { and, eq, gte, lte, desc, count } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';

@Injectable()
export class AuditLogsService {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  async getLogs(query: {
    tenantId: string;
    action?: string;
    entityType?: string;
    userId?: string;
    from?: string;
    to?: string;
    page?: number;
    limit?: number;
  }) {
    const { tenantId, action, entityType, userId, from, to, page = 1, limit = 50 } = query;
    const offset = (page - 1) * limit;

    const conditions = [eq(schema.auditLogs.tenantId, tenantId)];
    if (action) conditions.push(eq(schema.auditLogs.action, action));
    if (entityType) conditions.push(eq(schema.auditLogs.entityType, entityType));
    if (userId) conditions.push(eq(schema.auditLogs.userId, userId));
    if (from) conditions.push(gte(schema.auditLogs.createdAt, new Date(from)));
    if (to) conditions.push(lte(schema.auditLogs.createdAt, new Date(to)));

    const where = and(...conditions);

    const [rows, [{ total }]] = await Promise.all([
      this.db
        .select()
        .from(schema.auditLogs)
        .where(where)
        .orderBy(desc(schema.auditLogs.createdAt))
        .limit(limit)
        .offset(offset),
      this.db
        .select({ total: count(schema.auditLogs.id) })
        .from(schema.auditLogs)
        .where(where),
    ]);

    return {
      data: rows,
      meta: {
        total: Number(total),
        page,
        limit,
        pages: Math.ceil(Number(total) / limit),
      },
    };
  }
}
