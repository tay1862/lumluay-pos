import {
  pgTable,
  pgEnum,
  uuid,
  varchar,
  text,
  boolean,
  integer,
  numeric,
  timestamp,
  index,
  uniqueIndex,
} from 'drizzle-orm/pg-core';
import { relations, sql } from 'drizzle-orm';
import { tenants } from './tenants';

export const couponTypeEnum = pgEnum('coupon_type', [
  'percent',
  'fixed',
  'free_item',
]);

// ─── Coupons ──────────────────────────────────────────────────────────────────
export const coupons = pgTable(
  'coupons',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    code: varchar('code', { length: 50 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    description: text('description'),
    type: couponTypeEnum('type').notNull(),
    value: numeric('value', { precision: 18, scale: 4 }).notNull(),
    minOrderAmount: numeric('min_order_amount', { precision: 18, scale: 4 }),
    maxDiscountAmount: numeric('max_discount_amount', {
      precision: 18,
      scale: 4,
    }),
    usageLimit: integer('usage_limit'),
    usageCount: integer('usage_count').notNull().default(0),
    perUserLimit: integer('per_user_limit'),
    isActive: boolean('is_active').notNull().default(true),
    startsAt: timestamp('starts_at', { withTimezone: true }),
    expiresAt: timestamp('expires_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (table) => ({
    tenantIdx: index('idx_coupons_tenant').on(table.tenantId),
    codeIdx: uniqueIndex('idx_coupons_code')
      .on(table.tenantId, table.code)
      .where(sql`${table.deletedAt} IS NULL`),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const couponsRelations = relations(coupons, ({ one }) => ({
  tenant: one(tenants, {
    fields: [coupons.tenantId],
    references: [tenants.id],
  }),
}));
