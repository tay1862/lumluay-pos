import {
  pgTable,
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
import { relations } from 'drizzle-orm';
import { tenants } from './tenants';
import { orders } from './orders';

// ─── Members ──────────────────────────────────────────────────────────────────
export const members = pgTable(
  'members',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    memberCode: varchar('member_code', { length: 50 }),
    name: varchar('name', { length: 255 }).notNull(),
    phone: varchar('phone', { length: 50 }),
    email: varchar('email', { length: 255 }),
    birthDate: timestamp('birth_date', { withTimezone: true }),
    gender: varchar('gender', { length: 10 }),
    points: integer('points').notNull().default(0),
    totalSpent: numeric('total_spent', { precision: 18, scale: 4 })
      .notNull()
      .default('0'),
    visitCount: integer('visit_count').notNull().default(0),
    tier: varchar('tier', { length: 50 }).default('standard'),
    note: text('note'),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    tenantIdx: index('idx_members_tenant').on(table.tenantId),
    phoneIdx: uniqueIndex('idx_members_phone').on(table.tenantId, table.phone),
    codeIdx: uniqueIndex('idx_members_code').on(
      table.tenantId,
      table.memberCode,
    ),
  }),
);

// ─── Point Transactions ───────────────────────────────────────────────────────
export const pointTransactions = pgTable(
  'point_transactions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    memberId: uuid('member_id')
      .notNull()
      .references(() => members.id),
    orderId: uuid('order_id').references(() => orders.id),
    points: integer('points').notNull(),
    type: varchar('type', { length: 20 }).notNull(),
    description: text('description'),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (table) => ({
    memberIdx: index('idx_point_txn_member').on(table.memberId),
    tenantIdx: index('idx_point_txn_tenant').on(table.tenantId),
  }),
);

// ─── Relations ────────────────────────────────────────────────────────────────
export const membersRelations = relations(members, ({ one, many }) => ({
  tenant: one(tenants, {
    fields: [members.tenantId],
    references: [tenants.id],
  }),
  pointTransactions: many(pointTransactions),
}));

export const pointTransactionsRelations = relations(
  pointTransactions,
  ({ one }) => ({
    member: one(members, {
      fields: [pointTransactions.memberId],
      references: [members.id],
    }),
    order: one(orders, {
      fields: [pointTransactions.orderId],
      references: [orders.id],
    }),
  }),
);
