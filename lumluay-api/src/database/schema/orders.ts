import {
  pgTable,
  pgEnum,
  uuid,
  varchar,
  text,
  boolean,
  integer,
  numeric,
  jsonb,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { relations, sql } from 'drizzle-orm';
import { tenants } from './tenants';
import { users } from './users';
import { tables } from './tables';
import { products } from './products';
import { productVariants, modifierOptions } from './products';

export const orderStatusEnum = pgEnum('order_status', [
  'open',
  'held',
  'preparing',
  'ready',
  'served',
  'completed',
  'cancelled',
  'refunded',
]);

export const orderTypeEnum = pgEnum('order_type', [
  'dine_in',
  'takeaway',
  'delivery',
]);

export const orderItemStatusEnum = pgEnum('order_item_status', [
  'pending',
  'preparing',
  'ready',
  'served',
  'cancelled',
]);

// ─── Orders ───────────────────────────────────────────────────────────────────
export const orders = pgTable(
  'orders',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    receiptNumber: varchar('receipt_number', { length: 50 }).notNull(),
    orderType: orderTypeEnum('order_type').notNull().default('dine_in'),
    status: orderStatusEnum('status').notNull().default('open'),
    tableId: uuid('table_id').references(() => tables.id),
    customerId: uuid('customer_id'),
    staffId: uuid('staff_id').references(() => users.id),
    guestCount: integer('guest_count').default(1),
    note: text('note'),
    subtotal: numeric('subtotal', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    discountAmount: numeric('discount_amount', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    taxAmount: numeric('tax_amount', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    serviceChargeAmount: numeric('service_charge_amount', {
      precision: 18,
      scale: 4,
    })
      .notNull()
      .default('0'),
    totalAmount: numeric('total_amount', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    paidAmount: numeric('paid_amount', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    changeAmount: numeric('change_amount', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    isTrainingMode: boolean('is_training_mode').notNull().default(false),
    // Void / refund tracking
    voidedBy: uuid('voided_by').references(() => users.id),
    voidedAt: timestamp('voided_at', { withTimezone: true }),
    voidReason: text('void_reason'),
    refundOf: uuid('refund_of'),
    refundedAmount: numeric('refunded_amount', { precision: 18, scale: 4 }),
    // Discount tracking
    discountType: varchar('discount_type', { length: 20 }),
    discountValue: numeric('discount_value', { precision: 18, scale: 4 }),
    couponId: uuid('coupon_id'),
    // Rounding
    roundingAmount: numeric('rounding_amount', { precision: 18, scale: 4 }).default('0'),
    currency: varchar('currency', { length: 3 }).default('THB'),
    shiftId: uuid('shift_id'),
    waiterId: uuid('waiter_id').references(() => users.id),
    openedAt: timestamp('opened_at', { withTimezone: true }),
    extra: jsonb('extra').notNull().default(sql`'{}'::jsonb`),
    completedAt: timestamp('completed_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_orders_tenant').on(table.tenantId),
    statusIdx: index('idx_orders_status').on(table.tenantId, table.status),
    tableIdx: index('idx_orders_table').on(table.tableId),
    receiptIdx: index('idx_orders_receipt').on(
      table.tenantId,
      table.receiptNumber,
    ),
    createdIdx: index('idx_orders_created').on(table.tenantId, table.createdAt),
  }),
);

// ─── Order Items ──────────────────────────────────────────────────────────────
export const orderItems = pgTable(
  'order_items',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    orderId: uuid('order_id')
      .notNull()
      .references(() => orders.id),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    productId: uuid('product_id')
      .notNull()
      .references(() => products.id),
    variantId: uuid('variant_id').references(() => productVariants.id),
    productName: varchar('product_name', { length: 255 }).notNull(),
    variantName: varchar('variant_name', { length: 255 }),
    quantity: numeric('quantity', { precision: 18, scale: 4 }).notNull().default('1'),
    unitPrice: numeric('unit_price', { precision: 18, scale: 4 }).notNull(),
    discountAmount: numeric('discount_amount', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    lineTotal: numeric('line_total', { precision: 18, scale: 4 }).notNull(),
    status: orderItemStatusEnum('status').notNull().default('pending'),
    note: text('note'),
    courseNumber: integer('course_number').default(1),
    servedAt: timestamp('served_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    orderIdx: index('idx_order_items_order').on(table.orderId),
    tenantIdx: index('idx_order_items_tenant').on(table.tenantId),
  }),
);

// ─── Order Item Modifiers ─────────────────────────────────────────────────────
export const orderItemModifiers = pgTable(
  'order_item_modifiers',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    orderItemId: uuid('order_item_id')
      .notNull()
      .references(() => orderItems.id),
    modifierOptionId: uuid('modifier_option_id').references(
      () => modifierOptions.id,
    ),
    name: varchar('name', { length: 255 }).notNull(),
    extraPrice: numeric('extra_price', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    quantity: integer('quantity').notNull().default(1),
  },
  (table) => ({
    itemIdx: index('idx_oim_order_item').on(table.orderItemId),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const ordersRelations = relations(orders, ({ one, many }) => ({
  tenant: one(tenants, {
    fields: [orders.tenantId],
    references: [tenants.id],
  }),
  table: one(tables, { fields: [orders.tableId], references: [tables.id] }),
  staff: one(users, { fields: [orders.staffId], references: [users.id] }),
  items: many(orderItems),
}));

export const orderItemsRelations = relations(orderItems, ({ one, many }) => ({
  order: one(orders, { fields: [orderItems.orderId], references: [orders.id] }),
  product: one(products, {
    fields: [orderItems.productId],
    references: [products.id],
  }),
  modifiers: many(orderItemModifiers),
}));

export const orderItemModifiersRelations = relations(
  orderItemModifiers,
  ({ one }) => ({
    orderItem: one(orderItems, {
      fields: [orderItemModifiers.orderItemId],
      references: [orderItems.id],
    }),
  }),
);
