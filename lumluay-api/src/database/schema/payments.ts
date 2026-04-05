import {
  pgTable,
  pgEnum,
  uuid,
  varchar,
  text,
  numeric,
  jsonb,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { relations, sql } from 'drizzle-orm';
import { tenants } from './tenants';
import { orders } from './orders';
import { users } from './users';

export const paymentMethodEnum = pgEnum('payment_method', [
  'cash',
  'credit_card',
  'debit_card',
  'qr_promptpay',
  'bank_transfer',
  'wallet_truemoney',
  'wallet_linepay',
  'wallet_rabbit',
  'member_points',
  'coupon',
  'mixed',
]);

export const paymentStatusEnum = pgEnum('payment_status', [
  'pending',
  'completed',
  'failed',
  'refunded',
  'partially_refunded',
]);

// ─── Payments ─────────────────────────────────────────────────────────────────
export const payments = pgTable(
  'payments',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    orderId: uuid('order_id')
      .notNull()
      .references(() => orders.id),
    cashierId: uuid('cashier_id').references(() => users.id),
    method: paymentMethodEnum('method').notNull(),
    status: paymentStatusEnum('status').notNull().default('pending'),
    amount: numeric('amount', { precision: 18, scale: 4 }).notNull(),
    tendered: numeric('tendered', { precision: 18, scale: 4 }),
    change: numeric('change', { precision: 18, scale: 4 }),
    currency: varchar('currency', { length: 3 }).default('LAK'),
    exchangeRate: numeric('exchange_rate', { precision: 18, scale: 6 }),
    amountInBase: numeric('amount_in_base', { precision: 18, scale: 4 }),
    reference: varchar('reference', { length: 255 }),
    qrPayload: text('qr_payload'),
    note: text('note'),
    extra: jsonb('extra').notNull().default(sql`'{}'::jsonb`),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_payments_tenant').on(table.tenantId),
    orderIdx: index('idx_payments_order').on(table.orderId),
    statusIdx: index('idx_payments_status').on(table.tenantId, table.status),
    createdIdx: index('idx_payments_created').on(
      table.tenantId,
      table.createdAt,
    ),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const paymentsRelations = relations(payments, ({ one }) => ({
  tenant: one(tenants, {
    fields: [payments.tenantId],
    references: [tenants.id],
  }),
  order: one(orders, { fields: [payments.orderId], references: [orders.id] }),
  cashier: one(users, {
    fields: [payments.cashierId],
    references: [users.id],
  }),
}));
