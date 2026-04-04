import {
  pgTable,
  uuid,
  varchar,
  text,
  boolean,
  numeric,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';
import { tenants } from './tenants';

// ─── Subscription Plans ───────────────────────────────────────────────────────
export const subscriptionPlans = pgTable('subscription_plans', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 100 }).notNull(),
  slug: varchar('slug', { length: 50 }).notNull().unique(),
  description: text('description'),
  monthlyPrice: numeric('monthly_price', { precision: 18, scale: 4 }).notNull(),
  yearlyPrice: numeric('yearly_price', { precision: 18, scale: 4 }),
  maxUsers: numeric('max_users', { precision: 5, scale: 0 }),
  maxProducts: numeric('max_products', { precision: 8, scale: 0 }),
  maxBranches: numeric('max_branches', { precision: 5, scale: 0 }),
  features: text('features').array(),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true })
    .notNull()
    .defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true })
    .notNull()
    .defaultNow(),
});

// ─── Subscriptions ────────────────────────────────────────────────────────────
export const subscriptions = pgTable(
  'subscriptions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    planId: uuid('plan_id')
      .notNull()
      .references(() => subscriptionPlans.id),
    status: varchar('status', { length: 20 }).notNull().default('active'),
    billingCycle: varchar('billing_cycle', { length: 20 }).default('monthly'),
    amount: numeric('amount', { precision: 18, scale: 4 }).notNull(),
    startsAt: timestamp('starts_at', { withTimezone: true }).notNull(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    autoRenew: boolean('auto_renew').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_subscriptions_tenant').on(table.tenantId),
    statusIdx: index('idx_subscriptions_status').on(
      table.tenantId,
      table.status,
    ),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const subscriptionsRelations = relations(subscriptions, ({ one }) => ({
  tenant: one(tenants, {
    fields: [subscriptions.tenantId],
    references: [tenants.id],
  }),
  plan: one(subscriptionPlans, {
    fields: [subscriptions.planId],
    references: [subscriptionPlans.id],
  }),
}));

export const subscriptionPlansRelations = relations(
  subscriptionPlans,
  ({ many }) => ({
    subscriptions: many(subscriptions),
  }),
);
