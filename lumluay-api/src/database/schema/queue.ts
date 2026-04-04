import {
  pgTable,
  pgEnum,
  uuid,
  varchar,
  text,
  integer,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';
import { tenants } from './tenants';
import { members } from './members';
import { orders } from './orders';

export const queueStatusEnum = pgEnum('queue_status', [
  'waiting',
  'called',
  'seated',
  'cancelled',
  'no_show',
]);

// ─── Queue ────────────────────────────────────────────────────────────────────
export const queue = pgTable(
  'queue',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    memberId: uuid('member_id').references(() => members.id),
    name: varchar('name', { length: 255 }).notNull(),
    phone: varchar('phone', { length: 50 }),
    guestCount: integer('guest_count').notNull().default(1),
    ticketNumber: varchar('ticket_number', { length: 20 }).notNull(),
    status: queueStatusEnum('status').notNull().default('waiting'),
    note: text('note'),
    estimatedWaitMinutes: integer('estimated_wait_minutes'),
    orderId: uuid('order_id').references(() => orders.id),
    calledAt: timestamp('called_at', { withTimezone: true }),
    seatedAt: timestamp('seated_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_queue_tenant').on(table.tenantId),
    statusIdx: index('idx_queue_status').on(table.tenantId, table.status),
    createdIdx: index('idx_queue_created').on(table.tenantId, table.createdAt),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const queueRelations = relations(queue, ({ one }) => ({
  tenant: one(tenants, {
    fields: [queue.tenantId],
    references: [tenants.id],
  }),
  member: one(members, {
    fields: [queue.memberId],
    references: [members.id],
  }),
  order: one(orders, { fields: [queue.orderId], references: [orders.id] }),
}));
