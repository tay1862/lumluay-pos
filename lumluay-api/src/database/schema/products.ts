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
  uniqueIndex,
} from 'drizzle-orm/pg-core';
import { relations, sql } from 'drizzle-orm';
import { tenants } from './tenants';
import { categories } from './categories';

export const productTypeEnum = pgEnum('product_type', [
  'simple',
  'variant',
  'combo',
  'open_price',
  'bundle',
]);

// ─── Products ─────────────────────────────────────────────────────────────────
export const products = pgTable(
  'products',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    categoryId: uuid('category_id').references(() => categories.id),
    sku: varchar('sku', { length: 100 }),
    barcode: varchar('barcode', { length: 100 }),
    name: varchar('name', { length: 255 }).notNull(),
    nameEn: varchar('name_en', { length: 255 }),
    description: text('description'),
    imageUrl: text('image_url'),
    productType: productTypeEnum('product_type').notNull().default('simple'),
    basePrice: numeric('base_price', { precision: 18, scale: 4 }).notNull(),
    cost: numeric('cost', { precision: 18, scale: 4 }),
    unit: varchar('unit', { length: 50 }),
    trackStock: boolean('track_stock').notNull().default(false),
    allowModifiers: boolean('allow_modifiers').notNull().default(false),
    isActive: boolean('is_active').notNull().default(true),
    sortOrder: integer('sort_order').notNull().default(0),
    tags: jsonb('tags').notNull().default(sql`'[]'::jsonb`),
    extra: jsonb('extra').notNull().default(sql`'{}'::jsonb`),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (table) => ({
    tenantIdx: index('idx_products_tenant').on(table.tenantId),
    categoryIdx: index('idx_products_category').on(table.categoryId),
    // Partial unique index: only enforce SKU uniqueness for non-deleted products
    // so that a soft-deleted product's SKU can be reused.
    skuIdx: uniqueIndex('idx_products_sku')
      .on(table.tenantId, table.sku)
      .where(sql`${table.deletedAt} IS NULL AND ${table.sku} IS NOT NULL`),
    barcodeIdx: index('idx_products_barcode').on(table.tenantId, table.barcode),
  }),
);

// ─── Product Variants ─────────────────────────────────────────────────────────
export const productVariants = pgTable(
  'product_variants',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    productId: uuid('product_id')
      .notNull()
      .references(() => products.id),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    sku: varchar('sku', { length: 100 }),
    name: varchar('name', { length: 255 }).notNull(),
    price: numeric('price', { precision: 18, scale: 4 }).notNull(),
    cost: numeric('cost', { precision: 18, scale: 4 }),
    attributes: jsonb('attributes').notNull().default(sql`'{}'::jsonb`),
    isActive: boolean('is_active').notNull().default(true),
    sortOrder: integer('sort_order').notNull().default(0),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    productIdx: index('idx_variants_product').on(table.productId),
    tenantIdx: index('idx_variants_tenant').on(table.tenantId),
  }),
);

// ─── Unit Conversions ───────────────────────────────────────────────────────
export const unitConversions = pgTable(
  'unit_conversions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    productId: uuid('product_id')
      .notNull()
      .references(() => products.id),
    fromUnit: varchar('from_unit', { length: 50 }).notNull(),
    toUnit: varchar('to_unit', { length: 50 }).notNull(),
    conversionRate: numeric('conversion_rate', { precision: 12, scale: 6 }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_unit_conversions_tenant').on(table.tenantId),
    productIdx: index('idx_unit_conversions_product').on(table.productId),
    uniqueDirectionIdx: uniqueIndex('uidx_unit_conversions_direction').on(
      table.productId,
      table.fromUnit,
      table.toUnit,
    ),
  }),
);

// ─── Modifier Groups ──────────────────────────────────────────────────────────
export const modifierGroups = pgTable(
  'modifier_groups',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    name: varchar('name', { length: 255 }).notNull(),
    nameEn: varchar('name_en', { length: 255 }),
    isRequired: boolean('is_required').notNull().default(false),
    minSelect: integer('min_select').notNull().default(0),
    maxSelect: integer('max_select').notNull().default(1),
    isActive: boolean('is_active').notNull().default(true),
    sortOrder: integer('sort_order').notNull().default(0),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_modifier_groups_tenant').on(table.tenantId),
  }),
);

// ─── Modifier Options ─────────────────────────────────────────────────────────
export const modifierOptions = pgTable(
  'modifier_options',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    groupId: uuid('group_id')
      .notNull()
      .references(() => modifierGroups.id),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    name: varchar('name', { length: 255 }).notNull(),
    nameEn: varchar('name_en', { length: 255 }),
    extraPrice: numeric('extra_price', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    isDefault: boolean('is_default').notNull().default(false),
    isActive: boolean('is_active').notNull().default(true),
    sortOrder: integer('sort_order').notNull().default(0),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    groupIdx: index('idx_modifier_options_group').on(table.groupId),
    tenantIdx: index('idx_modifier_options_tenant').on(table.tenantId),
  }),
);

// ─── Product Modifier Groups (M:M) ────────────────────────────────────────────
export const productModifierGroups = pgTable(
  'product_modifier_groups',
  {
    productId: uuid('product_id')
      .notNull()
      .references(() => products.id),
    groupId: uuid('group_id')
      .notNull()
      .references(() => modifierGroups.id),
    sortOrder: integer('sort_order').notNull().default(0),
  },
  (table) => ({
    productIdx: index('idx_pmg_product').on(table.productId),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const productsRelations = relations(products, ({ one, many }) => ({
  tenant: one(tenants, {
    fields: [products.tenantId],
    references: [tenants.id],
  }),
  category: one(categories, {
    fields: [products.categoryId],
    references: [categories.id],
  }),
  variants: many(productVariants),
  unitConversions: many(unitConversions),
  modifierGroups: many(productModifierGroups),
}));

export const productVariantsRelations = relations(
  productVariants,
  ({ one }) => ({
    product: one(products, {
      fields: [productVariants.productId],
      references: [products.id],
    }),
  }),
);

export const unitConversionsRelations = relations(
  unitConversions,
  ({ one }) => ({
    product: one(products, {
      fields: [unitConversions.productId],
      references: [products.id],
    }),
  }),
);

export const modifierGroupsRelations = relations(
  modifierGroups,
  ({ one, many }) => ({
    tenant: one(tenants, {
      fields: [modifierGroups.tenantId],
      references: [tenants.id],
    }),
    options: many(modifierOptions),
    productGroups: many(productModifierGroups),
  }),
);

export const modifierOptionsRelations = relations(
  modifierOptions,
  ({ one }) => ({
    group: one(modifierGroups, {
      fields: [modifierOptions.groupId],
      references: [modifierGroups.id],
    }),
  }),
);

export const productModifierGroupsRelations = relations(
  productModifierGroups,
  ({ one }) => ({
    product: one(products, {
      fields: [productModifierGroups.productId],
      references: [products.id],
    }),
    group: one(modifierGroups, {
      fields: [productModifierGroups.groupId],
      references: [modifierGroups.id],
    }),
  }),
);
