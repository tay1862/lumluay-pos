import {
  pgTable,
  uuid,
  varchar,
  text,
  jsonb,
  inet,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { relations, sql } from 'drizzle-orm';
import { tenants } from './tenants';
import { users } from './users';

// ─── Audit Logs ───────────────────────────────────────────────────────────────
export const auditLogs = pgTable(
  'audit_logs',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id').references(() => tenants.id),
    userId: uuid('user_id').references(() => users.id),
    action: varchar('action', { length: 100 }).notNull(),
    entityType: varchar('entity_type', { length: 100 }),
    entityId: uuid('entity_id'),
    oldData: jsonb('old_data'),
    newData: jsonb('new_data'),
    ipAddress: inet('ip_address'),
    userAgent: text('user_agent'),
    extra: jsonb('extra').notNull().default(sql`'{}'::jsonb`),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_audit_logs_tenant').on(table.tenantId),
    userIdx: index('idx_audit_logs_user').on(table.userId),
    entityIdx: index('idx_audit_logs_entity').on(
      table.entityType,
      table.entityId,
    ),
    createdIdx: index('idx_audit_logs_created').on(
      table.tenantId,
      table.createdAt,
    ),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const auditLogsRelations = relations(auditLogs, ({ one }) => ({
  tenant: one(tenants, {
    fields: [auditLogs.tenantId],
    references: [tenants.id],
  }),
  user: one(users, { fields: [auditLogs.userId], references: [users.id] }),
}));
