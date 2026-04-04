import {
  pgTable,
  uuid,
  varchar,
  text,
  boolean,
  integer,
  jsonb,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { relations, sql } from 'drizzle-orm';
import { tenants } from './tenants';
import { users } from './users';

// ─── Sync Queue ───────────────────────────────────────────────────────────────
export const syncQueue = pgTable(
  'sync_queue',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    deviceId: varchar('device_id', { length: 255 }).notNull(),
    userId: uuid('user_id').references(() => users.id),
    operation: varchar('operation', { length: 20 }).notNull(),
    entityType: varchar('entity_type', { length: 100 }).notNull(),
    entityId: uuid('entity_id'),
    payload: jsonb('payload').notNull().default(sql`'{}'::jsonb`),
    checksum: varchar('checksum', { length: 64 }),
    isSynced: boolean('is_synced').notNull().default(false),
    retryCount: integer('retry_count').notNull().default(0),
    errorMessage: text('error_message'),
    syncedAt: timestamp('synced_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_sync_queue_tenant').on(table.tenantId),
    deviceIdx: index('idx_sync_queue_device').on(table.deviceId),
    syncedIdx: index('idx_sync_queue_synced').on(
      table.tenantId,
      table.isSynced,
    ),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const syncQueueRelations = relations(syncQueue, ({ one }) => ({
  tenant: one(tenants, {
    fields: [syncQueue.tenantId],
    references: [tenants.id],
  }),
  user: one(users, { fields: [syncQueue.userId], references: [users.id] }),
}));
