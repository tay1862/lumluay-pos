import { Injectable, NotFoundException } from '@nestjs/common';
import { eq, desc, count, sql, lte } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { DATABASE } from '@/database/database.module';
import { Inject } from '@nestjs/common';
import * as schema from '@/database/schema';

@Injectable()
export class AdminService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  async listTenants(page = 1, limit = 20) {
    const offset = (page - 1) * limit;

    const [tenants, [{ total }]] = await Promise.all([
      this.db
        .select()
        .from(schema.tenants)
        .orderBy(desc(schema.tenants.createdAt))
        .limit(limit)
        .offset(offset),
      this.db.select({ total: count(schema.tenants.id) }).from(schema.tenants),
    ]);

    return {
      data: tenants,
      meta: { total: Number(total), page, limit, pages: Math.ceil(Number(total) / limit) },
    };
  }

  async getTenantDetails(tenantId: string) {
    const [tenant] = await this.db
      .select()
      .from(schema.tenants)
      .where(eq(schema.tenants.id, tenantId));

    const [stats] = await this.db
      .select({
        userCount: count(schema.users.id),
      })
      .from(schema.users)
      .where(eq(schema.users.tenantId, tenantId));

    const [orderStats] = await this.db
      .select({
        totalOrders: count(schema.orders.id),
        totalRevenue: sql<number>`SUM(${schema.orders.totalAmount})`,
      })
      .from(schema.orders)
      .where(eq(schema.orders.tenantId, tenantId));

    return {
      tenant,
      stats: {
        users: Number(stats.userCount ?? 0),
        orders: Number(orderStats.totalOrders ?? 0),
        revenue: Number(orderStats.totalRevenue ?? 0),
      },
    };
  }

  async setTenantActive(tenantId: string, isActive: boolean) {
    const [tenant] = await this.db
      .update(schema.tenants)
      .set({ isActive, updatedAt: new Date() })
      .where(eq(schema.tenants.id, tenantId))
      .returning();

    return tenant;
  }

  async getSystemStats() {
    const [tenants, users, orders] = await Promise.all([
      this.db.select({ count: count(schema.tenants.id) }).from(schema.tenants),
      this.db.select({ count: count(schema.users.id) }).from(schema.users),
      this.db.select({ count: count(schema.orders.id) }).from(schema.orders),
    ]);

    return {
      tenants: Number(tenants[0].count),
      users: Number(users[0].count),
      orders: Number(orders[0].count),
    };
  }

  async listPlans() {
    return this.db
      .select()
      .from(schema.subscriptionPlans)
      .where(eq(schema.subscriptionPlans.isActive, true))
      .orderBy(schema.subscriptionPlans.monthlyPrice);
  }

  async updateTenant(
    tenantId: string,
    data: { name?: string; isActive?: boolean; subscriptionExpiresAt?: Date },
  ) {
    const [tenant] = await this.db
      .update(schema.tenants)
      .set({ ...data, updatedAt: new Date() })
      .where(eq(schema.tenants.id, tenantId))
      .returning();

    if (!tenant) throw new NotFoundException('Tenant not found');
    return tenant;
  }

  async getDashboard() {
    const now = new Date();
    const thirtyDaysFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const [stats, expiringTenants, revenueRows] = await Promise.all([
      this.getSystemStats(),
      this.db
        .select({ id: schema.tenants.id, name: schema.tenants.name })
        .from(schema.tenants)
        .where(lte(schema.tenants.subscriptionExpiresAt, thirtyDaysFromNow))
        .orderBy(schema.tenants.subscriptionExpiresAt)
        .limit(10),
      this.db
        .select({ total: sql<number>`COALESCE(SUM(${schema.orders.totalAmount}), 0)` })
        .from(schema.orders),
    ]);

    return {
      stats,
      expiringTenants,
      totalRevenue: Number(revenueRows[0]?.total ?? 0),
    };
  }

  async createPlan(data: {
    name: string;
    slug: string;
    description?: string;
    monthlyPrice: number;
    yearlyPrice?: number;
    maxUsers?: number;
    maxProducts?: number;
    maxBranches?: number;
    features?: string[];
  }) {
    const [plan] = await this.db
      .insert(schema.subscriptionPlans)
      .values({
        name: data.name,
        slug: data.slug,
        description: data.description,
        monthlyPrice: String(data.monthlyPrice),
        yearlyPrice: data.yearlyPrice != null ? String(data.yearlyPrice) : undefined,
        maxUsers: data.maxUsers != null ? String(data.maxUsers) : undefined,
        maxProducts: data.maxProducts != null ? String(data.maxProducts) : undefined,
        maxBranches: data.maxBranches != null ? String(data.maxBranches) : undefined,
        features: data.features,
      })
      .returning();
    return plan;
  }

  async updatePlan(
    planId: string,
    data: {
      name?: string;
      description?: string;
      monthlyPrice?: number;
      yearlyPrice?: number;
      maxUsers?: number;
      maxProducts?: number;
      maxBranches?: number;
      features?: string[];
      isActive?: boolean;
    },
  ) {
    const updatePayload: Record<string, unknown> = { updatedAt: new Date() };
    if (data.name !== undefined) updatePayload.name = data.name;
    if (data.description !== undefined) updatePayload.description = data.description;
    if (data.monthlyPrice !== undefined) updatePayload.monthlyPrice = String(data.monthlyPrice);
    if (data.yearlyPrice !== undefined) updatePayload.yearlyPrice = String(data.yearlyPrice);
    if (data.maxUsers !== undefined) updatePayload.maxUsers = String(data.maxUsers);
    if (data.maxProducts !== undefined) updatePayload.maxProducts = String(data.maxProducts);
    if (data.maxBranches !== undefined) updatePayload.maxBranches = String(data.maxBranches);
    if (data.features !== undefined) updatePayload.features = data.features;
    if (data.isActive !== undefined) updatePayload.isActive = data.isActive;

    const [plan] = await this.db
      .update(schema.subscriptionPlans)
      .set(updatePayload)
      .where(eq(schema.subscriptionPlans.id, planId))
      .returning();

    if (!plan) throw new NotFoundException('Plan not found');
    return plan;
  }

  async deletePlan(planId: string) {
    const [plan] = await this.db
      .update(schema.subscriptionPlans)
      .set({ isActive: false, updatedAt: new Date() })
      .where(eq(schema.subscriptionPlans.id, planId))
      .returning();

    if (!plan) throw new NotFoundException('Plan not found');
    return { success: true };
  }
}
