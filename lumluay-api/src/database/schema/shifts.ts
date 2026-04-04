import {
  pgTable,
  pgEnum,
  uuid,
  numeric,
  jsonb,
  timestamp,
  text,
  index,
} from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';
import { tenants } from './tenants';
import { users } from './users';

export const shiftStatusEnum = pgEnum('shift_status', [
  'open',
  'closed',
  'suspended',
]);

// ─── Shifts ───────────────────────────────────────────────────────────────────
export const shifts = pgTable(
  'shifts',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    cashierId: uuid('cashier_id')
      .notNull()
      .references(() => users.id),
    status: shiftStatusEnum('status').notNull().default('open'),
    openingCash: numeric('opening_cash', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    closingCash: numeric('closing_cash', { precision: 18, scale: 4 }),
    expectedCash: numeric('expected_cash', { precision: 18, scale: 4 }),
    cashDifference: numeric('cash_difference', { precision: 18, scale: 4 }),
    totalSales: numeric('total_sales', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    totalRefunds: numeric('total_refunds', { precision: 18, scale: 4 }).default('0'),
    salesByMethod: jsonb('sales_by_method'),
    totalOrders: numeric('total_orders', { precision: 6, scale: 0 })
      .notNull()
      .default('0'),
    note: text('note'),
    openedAt: timestamp('opened_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    closedAt: timestamp('closed_at', { withTimezone: true }),
  },
  (table) => ({
    tenantIdx: index('idx_shifts_tenant').on(table.tenantId),
    cashierIdx: index('idx_shifts_cashier').on(table.cashierId),
    statusIdx: index('idx_shifts_status').on(table.tenantId, table.status),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const shiftsRelations = relations(shifts, ({ one }) => ({
  tenant: one(tenants, {
    fields: [shifts.tenantId],
    references: [tenants.id],
  }),
  cashier: one(users, { fields: [shifts.cashierId], references: [users.id] }),
}));
