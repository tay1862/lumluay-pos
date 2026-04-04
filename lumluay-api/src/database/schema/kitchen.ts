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
import { orderItems } from './orders';
import { users } from './users';

export const kitchenStatusEnum = pgEnum('kitchen_status', [
  'pending',
  'preparing',
  'ready',
  'served',
  'cancelled',
]);

// ─── Kitchen Tickets ──────────────────────────────────────────────────────────
export const kitchenTickets = pgTable(
  'kitchen_tickets',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    orderItemId: uuid('order_item_id')
      .notNull()
      .references(() => orderItems.id),
    station: varchar('station', { length: 100 }),
    status: kitchenStatusEnum('status').notNull().default('pending'),
    priority: integer('priority').notNull().default(0),
    note: text('note'),
    assignedTo: uuid('assigned_to').references(() => users.id),
    startedAt: timestamp('started_at', { withTimezone: true }),
    readyAt: timestamp('ready_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_kitchen_tickets_tenant').on(table.tenantId),
    statusIdx: index('idx_kitchen_tickets_status').on(
      table.tenantId,
      table.status,
    ),
    stationIdx: index('idx_kitchen_tickets_station').on(
      table.tenantId,
      table.station,
    ),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const kitchenTicketsRelations = relations(kitchenTickets, ({ one }) => ({
  tenant: one(tenants, {
    fields: [kitchenTickets.tenantId],
    references: [tenants.id],
  }),
  orderItem: one(orderItems, {
    fields: [kitchenTickets.orderItemId],
    references: [orderItems.id],
  }),
  assignedUser: one(users, {
    fields: [kitchenTickets.assignedTo],
    references: [users.id],
  }),
}));
