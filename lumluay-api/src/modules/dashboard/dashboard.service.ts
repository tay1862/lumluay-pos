import { Injectable } from '@nestjs/common';
import { eq, and, gte, lte, desc, sum, count, sql } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';

@Injectable()
export class DashboardService {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  /** Summary KPIs for a date range (defaults to today) */
  async getSummary(tenantId: string, date: Date = new Date()) {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);

    const yesterday = new Date(date);
    yesterday.setDate(yesterday.getDate() - 1);
    const yStart = new Date(yesterday);
    yStart.setHours(0, 0, 0, 0);
    const yEnd = new Date(yesterday);
    yEnd.setHours(23, 59, 59, 999);

    const [today] = await this.db
      .select({
        totalOrders: count(schema.orders.id),
        totalRevenue: sum(schema.orders.totalAmount),
        totalCustomers: sql<number>`COUNT(DISTINCT ${schema.orders.customerId})`,
        avgOrderValue: sql<number>`AVG(${schema.orders.totalAmount})`,
      })
      .from(schema.orders)
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.orders.status, 'completed'),
          gte(schema.orders.createdAt, start),
          lte(schema.orders.createdAt, end),
        ),
      );

    const [yesterday_data] = await this.db
      .select({
        totalRevenue: sum(schema.orders.totalAmount),
        totalOrders: count(schema.orders.id),
      })
      .from(schema.orders)
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.orders.status, 'completed'),
          gte(schema.orders.createdAt, yStart),
          lte(schema.orders.createdAt, yEnd),
        ),
      );

    const todayRevenue = Number(today.totalRevenue ?? 0);
    const yestRevenue = Number(yesterday_data.totalRevenue ?? 0);
    const revenueGrowth =
      yestRevenue > 0
        ? ((todayRevenue - yestRevenue) / yestRevenue) * 100
        : null;

    const todayOrders = Number(today.totalOrders ?? 0);
    const yestOrders = Number(yesterday_data.totalOrders ?? 0);
    const ordersGrowth =
      yestOrders > 0
        ? ((todayOrders - yestOrders) / yestOrders) * 100
        : null;

    return {
      date: start.toISOString().split('T')[0],
      totalRevenue: todayRevenue,
      totalOrders: todayOrders,
      avgOrderValue: Number(today.avgOrderValue ?? 0),
      totalCustomers: Number(today.totalCustomers ?? 0),
      revenueGrowthPercent: revenueGrowth !== null ? parseFloat(revenueGrowth.toFixed(1)) : null,
      ordersGrowthPercent: ordersGrowth !== null ? parseFloat(ordersGrowth.toFixed(1)) : null,
    };
  }

  /** Hourly sales breakdown for a specific date */
  async getHourlySales(tenantId: string, date: Date = new Date()) {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);

    const rows = await this.db
      .select({
        hour: sql<number>`EXTRACT(HOUR FROM ${schema.orders.createdAt})`,
        revenue: sum(schema.orders.totalAmount),
        orders: count(schema.orders.id),
      })
      .from(schema.orders)
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.orders.status, 'completed'),
          gte(schema.orders.createdAt, start),
          lte(schema.orders.createdAt, end),
        ),
      )
      .groupBy(sql`EXTRACT(HOUR FROM ${schema.orders.createdAt})`)
      .orderBy(sql`EXTRACT(HOUR FROM ${schema.orders.createdAt})`);

    // Fill all 24 hours
    const hourMap = new Map(rows.map((r) => [Number(r.hour), r]));
    return Array.from({ length: 24 }, (_, h) => ({
      hour: h,
      revenue: Number(hourMap.get(h)?.revenue ?? 0),
      orders: Number(hourMap.get(h)?.orders ?? 0),
    }));
  }

  /** Top N products for a specific date */
  async getTopProducts(tenantId: string, date: Date = new Date(), limit = 10) {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);

    return this.db
      .select({
        productId: schema.orderItems.productId,
        productName: schema.products.name,
        totalQuantity: sum(schema.orderItems.quantity),
        totalRevenue: sum(schema.orderItems.lineTotal),
      })
      .from(schema.orderItems)
      .innerJoin(schema.orders, eq(schema.orderItems.orderId, schema.orders.id))
      .innerJoin(schema.products, eq(schema.orderItems.productId, schema.products.id))
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.orders.status, 'completed'),
          gte(schema.orders.createdAt, start),
          lte(schema.orders.createdAt, end),
        ),
      )
      .groupBy(schema.orderItems.productId, schema.products.name)
      .orderBy(desc(sum(schema.orderItems.lineTotal)))
      .limit(limit);
  }

  /** Revenue breakdown by payment method for a specific date */
  async getSalesByMethod(tenantId: string, date: Date = new Date()) {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);

    const rows = await this.db
      .select({
        method: schema.payments.method,
        total: sum(schema.payments.amount),
        count: count(schema.payments.id),
      })
      .from(schema.payments)
      .innerJoin(schema.orders, eq(schema.payments.orderId, schema.orders.id))
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.payments.status, 'completed'),
          gte(schema.payments.createdAt, start),
          lte(schema.payments.createdAt, end),
        ),
      )
      .groupBy(schema.payments.method);

    return rows.map((r) => ({
      method: r.method,
      total: Number(r.total ?? 0),
      count: Number(r.count ?? 0),
    }));
  }
}
