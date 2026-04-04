import {
  pgTable,
  pgEnum,
  uuid,
  varchar,
  text,
  boolean,
  integer,
  timestamp,
  index,
} from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';
import { tenants } from './tenants';

export const tableStatusEnum = pgEnum('table_status', [
  'available',
  'occupied',
  'reserved',
  'cleaning',
]);

// ─── Zones ────────────────────────────────────────────────────────────────────
export const zones = pgTable(
  'zones',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    name: varchar('name', { length: 100 }).notNull(),
    description: text('description'),
    floorPlanUrl: text('floor_plan_url'),
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
    tenantIdx: index('idx_zones_tenant').on(table.tenantId),
  }),
);

// ─── Tables ───────────────────────────────────────────────────────────────────
export const tables = pgTable(
  'tables',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    zoneId: uuid('zone_id').references(() => zones.id),
    name: varchar('name', { length: 100 }).notNull(),
    capacity: integer('capacity').default(4),
    status: tableStatusEnum('status').notNull().default('available'),
    posX: integer('pos_x'),
    posY: integer('pos_y'),
    sortOrder: integer('sort_order').notNull().default(0),
    mergedIntoId: uuid('merged_into_id'),
    qrCode: text('qr_code'),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_tables_tenant').on(table.tenantId),
    zoneIdx: index('idx_tables_zone').on(table.zoneId),
    statusIdx: index('idx_tables_status').on(table.tenantId, table.status),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const zonesRelations = relations(zones, ({ one, many }) => ({
  tenant: one(tenants, { fields: [zones.tenantId], references: [tenants.id] }),
  tables: many(tables),
}));

export const tablesRelations = relations(tables, ({ one }) => ({
  tenant: one(tenants, {
    fields: [tables.tenantId],
    references: [tenants.id],
  }),
  zone: one(zones, { fields: [tables.zoneId], references: [zones.id] }),
}));
