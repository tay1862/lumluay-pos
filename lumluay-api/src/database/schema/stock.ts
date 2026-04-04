import {
  pgTable,
  pgEnum,
  uuid,
  varchar,
  text,
  numeric,
  integer,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';
import { tenants } from './tenants';
import { products } from './products';
import { productVariants } from './products';
import { users } from './users';
import { orders } from './orders';

export const stockMovementTypeEnum = pgEnum('stock_movement_type', [
  'purchase',
  'sale',
  'adjustment',
  'transfer',
  'return',
  'waste',
  'opening',
]);

// ─── Stock Levels ─────────────────────────────────────────────────────────────
export const stockLevels = pgTable(
  'stock_levels',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    productId: uuid('product_id')
      .notNull()
      .references(() => products.id),
    variantId: uuid('variant_id').references(() => productVariants.id),
    quantity: numeric('quantity', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    reservedQty: numeric('reserved_qty', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    lowStockThreshold: numeric('low_stock_threshold', {
      precision: 18,
      scale: 4,
    }),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_stock_levels_tenant').on(table.tenantId),
    productIdx: index('idx_stock_levels_product').on(table.productId),
  }),
);

// ─── Stock Movements ──────────────────────────────────────────────────────────
export const stockMovements = pgTable(
  'stock_movements',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    productId: uuid('product_id')
      .notNull()
      .references(() => products.id),
    variantId: uuid('variant_id').references(() => productVariants.id),
    type: stockMovementTypeEnum('type').notNull(),
    quantity: numeric('quantity', { precision: 18, scale: 4 }).notNull(),
    balanceBefore: numeric('balance_before', { precision: 18, scale: 4 }),
    balanceAfter: numeric('balance_after', { precision: 18, scale: 4 }),
    unitCost: numeric('unit_cost', { precision: 18, scale: 4 }),
    orderId: uuid('order_id').references(() => orders.id),
    userId: uuid('user_id').references(() => users.id),
    reference: varchar('reference', { length: 255 }),
    note: text('note'),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_stock_movements_tenant').on(table.tenantId),
    productIdx: index('idx_stock_movements_product').on(table.productId),
    typeIdx: index('idx_stock_movements_type').on(table.tenantId, table.type),
    createdIdx: index('idx_stock_movements_created').on(
      table.tenantId,
      table.createdAt,
    ),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const stockLevelsRelations = relations(stockLevels, ({ one }) => ({
  tenant: one(tenants, {
    fields: [stockLevels.tenantId],
    references: [tenants.id],
  }),
  product: one(products, {
    fields: [stockLevels.productId],
    references: [products.id],
  }),
}));

export const stockMovementsRelations = relations(stockMovements, ({ one }) => ({
  tenant: one(tenants, {
    fields: [stockMovements.tenantId],
    references: [tenants.id],
  }),
  product: one(products, {
    fields: [stockMovements.productId],
    references: [products.id],
  }),
  order: one(orders, {
    fields: [stockMovements.orderId],
    references: [orders.id],
  }),
  user: one(users, { fields: [stockMovements.userId], references: [users.id] }),
}));
