import {
  pgTable,
  uuid,
  varchar,
  text,
  boolean,
  integer,
  numeric,
  jsonb,
  timestamp,
  index,
  uniqueIndex,
} from 'drizzle-orm/pg-core';
import { relations, sql } from 'drizzle-orm';
import { tenants } from './tenants';

// ─── Store Settings ───────────────────────────────────────────────────────────
export const storeSettings = pgTable(
  'store_settings',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .unique()
      .references(() => tenants.id),
    // Store info
    storeName: jsonb('store_name'),
    storeAddress: jsonb('store_address'),
    storePhone: varchar('store_phone', { length: 50 }),
    storeEmail: varchar('store_email', { length: 255 }),
    // Receipt
    receiptHeader: text('receipt_header'),
    receiptFooter: text('receipt_footer'),
    receiptShowLogo: boolean('receipt_show_logo').notNull().default(true),
    receiptWidth: integer('receipt_width').default(80),
    receiptLogoUrl: text('receipt_logo_url'),
    receiptPrefix: varchar('receipt_prefix', { length: 20 }),
    // Tax
    defaultTaxRateId: uuid('default_tax_rate_id'),
    taxIncluded: boolean('tax_included').notNull().default(true),
    // Service charge
    serviceChargeEnabled: boolean('service_charge_enabled')
      .notNull()
      .default(false),
    serviceChargePercent: numeric('service_charge_percent', {
      precision: 5,
      scale: 2,
    }).default('0'),
    // Ordering
    requireTableForDineIn: boolean('require_table_for_dine_in')
      .notNull()
      .default(true),
    allowSplitBill: boolean('allow_split_bill').notNull().default(true),
    allowMergeBill: boolean('allow_merge_bill').notNull().default(true),
    allowDiscount: boolean('allow_discount').notNull().default(true),
    maxDiscountPercent: numeric('max_discount_percent', {
      precision: 5,
      scale: 2,
    }).default('100'),
    allowRefund: boolean('allow_refund').notNull().default(true),
    // Kitchen
    kitchenPrintEnabled: boolean('kitchen_print_enabled')
      .notNull()
      .default(false),
    // Low stock threshold
    lowStockThreshold: integer('low_stock_threshold').default(10),
    // Currency
    currenciesEnabled: jsonb('currencies_enabled'),
    exchangeRates: jsonb('exchange_rates'),
    // POS settings
    autoOpenCashDrawer: boolean('auto_open_cash_drawer').notNull().default(false),
    soundEnabled: boolean('sound_enabled').notNull().default(true),
    autoLockMinutes: integer('auto_lock_minutes'),
    defaultOrderType: varchar('default_order_type', { length: 20 }).default('dine_in'),
    printersConfig: jsonb('printers_config'),
    // Extra
    extra: jsonb('extra').notNull().default(sql`'{}'::jsonb`),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: uniqueIndex('idx_store_settings_tenant').on(table.tenantId),
  }),
);

// ─── Tax Rates ────────────────────────────────────────────────────────────────
export const taxRates = pgTable(
  'tax_rates',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    name: varchar('name', { length: 100 }).notNull(),
    rate: numeric('rate', { precision: 5, scale: 2 }).notNull(),
    isDefault: boolean('is_default').notNull().default(false),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_tax_rates_tenant').on(table.tenantId),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const storeSettingsRelations = relations(storeSettings, ({ one }) => ({
  tenant: one(tenants, {
    fields: [storeSettings.tenantId],
    references: [tenants.id],
  }),
}));

export const taxRatesRelations = relations(taxRates, ({ one }) => ({
  tenant: one(tenants, {
    fields: [taxRates.tenantId],
    references: [tenants.id],
  }),
}));
