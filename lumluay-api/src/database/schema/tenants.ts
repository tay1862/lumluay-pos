import {
  pgTable,
  uuid,
  varchar,
  text,
  boolean,
  timestamp,
  jsonb,
  index,
  uniqueIndex,
} from 'drizzle-orm/pg-core';
import { relations, sql } from 'drizzle-orm';
import { users } from './users';

// ─────────────────────────────────────────────────────────────────────────────
// TENANTS
// ─────────────────────────────────────────────────────────────────────────────
export const tenants = pgTable(
  'tenants',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    name: varchar('name', { length: 255 }).notNull(),
    slug: varchar('slug', { length: 100 }).notNull().unique(),
    logoUrl: text('logo_url'),
    ownerName: varchar('owner_name', { length: 255 }),
    phone: varchar('phone', { length: 50 }),
    email: varchar('email', { length: 255 }),
    address: text('address'),
    taxId: varchar('tax_id', { length: 50 }),
    defaultCurrency: varchar('default_currency', { length: 3 })
      .notNull()
      .default('LAK'),
    defaultLocale: varchar('default_locale', { length: 5 })
      .notNull()
      .default('lo'),
    timezone: varchar('timezone', { length: 50 })
      .notNull()
      .default('Asia/Bangkok'),
    isActive: boolean('is_active').notNull().default(true),
    isTrainingMode: boolean('is_training_mode').notNull().default(false),
    subscriptionPlan: varchar('subscription_plan', { length: 50 }),
    subscriptionExpiresAt: timestamp('subscription_expires_at', {
      withTimezone: true,
    }),
    licenseType: varchar('license_type', { length: 20 }),
    settings: jsonb('settings').notNull().default(sql`'{}'::jsonb`),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (table) => ({
    slugIdx: uniqueIndex('idx_tenants_slug').on(table.slug),
    activeIdx: index('idx_tenants_active').on(table.isActive),
  }),
);

export const tenantsRelations = relations(tenants, ({ many }) => ({
  users: many(users),
}));
