import { Injectable } from '@nestjs/common';
import { eq, and, gte, lte, desc, sum, count, sql } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';

@Injectable()
export class ReportsService {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  // ─── Summary ────────────────────────────────────────────────────────────────

  async getSummary(tenantId: string, from: Date, to: Date) {
    const [sales] = await this.db
      .select({
        totalOrders: count(schema.orders.id),
        totalRevenue: sum(schema.orders.totalAmount),
        totalDiscount: sum(schema.orders.discountAmount),
        avgOrderValue: sql<number>`AVG(${schema.orders.totalAmount})`,
      })
      .from(schema.orders)
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.orders.status, 'completed'),
          gte(schema.orders.createdAt, from),
          lte(schema.orders.createdAt, to),
        ),
      );

    const [payments] = await this.db
      .select({
        cashTotal: sql<number>`SUM(CASE WHEN ${schema.payments.method} = 'cash' THEN ${schema.payments.amount} ELSE 0 END)`,
        qrTotal: sql<number>`SUM(CASE WHEN ${schema.payments.method} = 'qr' THEN ${schema.payments.amount} ELSE 0 END)`,
        cardTotal: sql<number>`SUM(CASE WHEN ${schema.payments.method} = 'card' THEN ${schema.payments.amount} ELSE 0 END)`,
        walletTotal: sql<number>`SUM(CASE WHEN ${schema.payments.method} = 'wallet' THEN ${schema.payments.amount} ELSE 0 END)`,
      })
      .from(schema.payments)
      .innerJoin(schema.orders, eq(schema.payments.orderId, schema.orders.id))
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.payments.status, 'completed'),
          gte(schema.payments.createdAt, from),
          lte(schema.payments.createdAt, to),
        ),
      );

    return {
      period: { from, to },
      orders: {
        total: Number(sales.totalOrders ?? 0),
        revenue: Number(sales.totalRevenue ?? 0),
        discount: Number(sales.totalDiscount ?? 0),
        avgValue: Number(sales.avgOrderValue ?? 0),
      },
      paymentBreakdown: {
        cash: Number(payments.cashTotal ?? 0),
        qr: Number(payments.qrTotal ?? 0),
        card: Number(payments.cardTotal ?? 0),
        wallet: Number(payments.walletTotal ?? 0),
      },
    };
  }

  // ─── Daily breakdown ────────────────────────────────────────────────────────

  async getDailyBreakdown(tenantId: string, from: Date, to: Date) {
    return this.db
      .select({
        date: sql<string>`DATE(${schema.orders.createdAt})`,
        orderCount: count(schema.orders.id),
        revenue: sum(schema.orders.totalAmount),
        discount: sum(schema.orders.discountAmount),
      })
      .from(schema.orders)
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.orders.status, 'completed'),
          gte(schema.orders.createdAt, from),
          lte(schema.orders.createdAt, to),
        ),
      )
      .groupBy(sql`DATE(${schema.orders.createdAt})`)
      .orderBy(sql`DATE(${schema.orders.createdAt})`);
  }

  // ─── Top products ───────────────────────────────────────────────────────────

  async getTopProducts(tenantId: string, from: Date, to: Date, limit = 20) {
    return this.db
      .select({
        productId: schema.orderItems.productId,
        productName: schema.orderItems.productName,
        totalQty: sum(schema.orderItems.quantity),
        totalRevenue: sum(schema.orderItems.lineTotal),
        orderCount: count(schema.orderItems.id),
      })
      .from(schema.orderItems)
      .innerJoin(schema.orders, eq(schema.orderItems.orderId, schema.orders.id))
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.orders.status, 'completed'),
          gte(schema.orders.createdAt, from),
          lte(schema.orders.createdAt, to),
        ),
      )
      .groupBy(schema.orderItems.productId, schema.orderItems.productName)
      .orderBy(desc(sum(schema.orderItems.lineTotal)))
      .limit(limit);
  }

  // ─── Hourly heatmap ─────────────────────────────────────────────────────────

  async getHourlyBreakdown(tenantId: string, from: Date, to: Date) {
    return this.db
      .select({
        hour: sql<number>`EXTRACT(HOUR FROM ${schema.orders.createdAt})`,
        orderCount: count(schema.orders.id),
        revenue: sum(schema.orders.totalAmount),
      })
      .from(schema.orders)
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.orders.status, 'completed'),
          gte(schema.orders.createdAt, from),
          lte(schema.orders.createdAt, to),
        ),
      )
      .groupBy(sql`EXTRACT(HOUR FROM ${schema.orders.createdAt})`)
      .orderBy(sql`EXTRACT(HOUR FROM ${schema.orders.createdAt})`);
  }

  // ─── Stock movements ────────────────────────────────────────────────────────

  async getStockReport(tenantId: string, from: Date, to: Date) {
    return this.db
      .select({
        productId: schema.stockMovements.productId,
        type: schema.stockMovements.type,
        totalQty: sum(schema.stockMovements.quantity),
        entryCount: count(schema.stockMovements.id),
      })
      .from(schema.stockMovements)
      .where(
        and(
          eq(schema.stockMovements.tenantId, tenantId),
          gte(schema.stockMovements.createdAt, from),
          lte(schema.stockMovements.createdAt, to),
        ),
      )
      .groupBy(schema.stockMovements.productId, schema.stockMovements.type)
      .orderBy(schema.stockMovements.productId);
  }

  // ─── Members report ─────────────────────────────────────────────────────────

  async getMembersReport(tenantId: string, from: Date, to: Date) {
    const [stats] = await this.db
      .select({
        newMembers: count(schema.members.id),
      })
      .from(schema.members)
      .where(
        and(
          eq(schema.members.tenantId, tenantId),
          gte(schema.members.createdAt, from),
          lte(schema.members.createdAt, to),
        ),
      );

    const [totals] = await this.db
      .select({
        totalMembers: count(schema.members.id),
      })
      .from(schema.members)
      .where(eq(schema.members.tenantId, tenantId));

    return {
      newInPeriod: Number(stats.newMembers ?? 0),
      total: Number(totals.totalMembers ?? 0),
    };
  }

  // ─── Sales by payment method ────────────────────────────────────────────────

  async getPaymentMethodReport(tenantId: string, from: Date, to: Date) {
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
          gte(schema.payments.createdAt, from),
          lte(schema.payments.createdAt, to),
        ),
      )
      .groupBy(schema.payments.method)
      .orderBy(desc(sum(schema.payments.amount)));

    return rows.map((r) => ({
      method: r.method,
      total: Number(r.total ?? 0),
      count: Number(r.count ?? 0),
    }));
  }

  // ─── Sales by category ──────────────────────────────────────────────────────

  async getCategoryReport(tenantId: string, from: Date, to: Date) {
    return this.db
      .select({
        categoryId: schema.products.categoryId,
        categoryName: schema.categories.name,
        totalQuantity: sum(schema.orderItems.quantity),
        totalRevenue: sum(schema.orderItems.lineTotal),
        orderCount: count(schema.orderItems.id),
      })
      .from(schema.orderItems)
      .innerJoin(schema.orders, eq(schema.orderItems.orderId, schema.orders.id))
      .innerJoin(schema.products, eq(schema.orderItems.productId, schema.products.id))
      .innerJoin(schema.categories, eq(schema.products.categoryId, schema.categories.id))
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.orders.status, 'completed'),
          gte(schema.orders.createdAt, from),
          lte(schema.orders.createdAt, to),
        ),
      )
      .groupBy(schema.products.categoryId, schema.categories.name)
      .orderBy(desc(sum(schema.orderItems.lineTotal)));
  }

  // ─── 15.1.6 Sales report with group-by ──────────────────────────────────────

  async getSalesReport(
    tenantId: string,
    from: Date,
    to: Date,
    groupBy: 'day' | 'week' | 'month' = 'day',
  ) {
    const dateExpr =
      groupBy === 'month'
        ? sql`DATE_TRUNC('month', ${schema.orders.createdAt})::text`
        : groupBy === 'week'
          ? sql`DATE_TRUNC('week', ${schema.orders.createdAt})::text`
          : sql`DATE(${schema.orders.createdAt})::text`;

    const rows = await this.db
      .select({
        period: sql<string>`${dateExpr}`,
        orderCount: count(schema.orders.id),
        revenue: sum(schema.orders.totalAmount),
        discount: sum(schema.orders.discountAmount),
      })
      .from(schema.orders)
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.orders.status, 'completed'),
          gte(schema.orders.createdAt, from),
          lte(schema.orders.createdAt, to),
        ),
      )
      .groupBy(dateExpr)
      .orderBy(dateExpr);

    return rows.map((r) => ({
      period: r.period,
      orderCount: Number(r.orderCount ?? 0),
      revenue: Number(r.revenue ?? 0),
      discount: Number(r.discount ?? 0),
      net: Number(r.revenue ?? 0) - Number(r.discount ?? 0),
    }));
  }

  // ─── 15.1.7 Product sales report ────────────────────────────────────────────

  async getProductsReport(tenantId: string, from: Date, to: Date, limit = 100) {
    const rows = await this.db
      .select({
        productId: schema.orderItems.productId,
        productName: schema.orderItems.productName,
        categoryName: schema.categories.name,
        totalQty: sum(schema.orderItems.quantity),
        totalRevenue: sum(schema.orderItems.lineTotal),
        orderCount: count(schema.orderItems.id),
      })
      .from(schema.orderItems)
      .innerJoin(schema.orders, eq(schema.orderItems.orderId, schema.orders.id))
      .leftJoin(schema.products, eq(schema.orderItems.productId, schema.products.id))
      .leftJoin(schema.categories, eq(schema.products.categoryId, schema.categories.id))
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.orders.status, 'completed'),
          gte(schema.orders.createdAt, from),
          lte(schema.orders.createdAt, to),
        ),
      )
      .groupBy(
        schema.orderItems.productId,
        schema.orderItems.productName,
        schema.categories.name,
      )
      .orderBy(desc(sum(schema.orderItems.lineTotal)))
      .limit(limit);

    return rows.map((r, idx) => ({
      rank: idx + 1,
      productId: r.productId,
      productName: r.productName,
      categoryName: r.categoryName ?? '-',
      totalQty: Number(r.totalQty ?? 0),
      totalRevenue: Number(r.totalRevenue ?? 0),
      orderCount: Number(r.orderCount ?? 0),
    }));
  }

  // ─── 15.1.10 Export CSV ─────────────────────────────────────────────────────

  async exportCsv(
    tenantId: string,
    from: Date,
    to: Date,
    type: 'sales' | 'products',
  ): Promise<string> {
    if (type === 'products') {
      const rows = await this.getProductsReport(tenantId, from, to, 9999);
      const header = 'Rank,Product,Category,Qty Sold,Revenue,Orders';
      const lines = rows.map(
        (r) =>
          `${r.rank},"${r.productName}","${r.categoryName}",${r.totalQty},${r.totalRevenue.toFixed(2)},${r.orderCount}`,
      );
      return [header, ...lines].join('\n');
    } else {
      const rows = await this.getSalesReport(tenantId, from, to);
      const header = 'Date,Orders,Revenue,Discount,Net';
      const lines = rows.map(
        (r) =>
          `${r.period},${r.orderCount},${r.revenue.toFixed(2)},${r.discount.toFixed(2)},${r.net.toFixed(2)}`,
      );
      return [header, ...lines].join('\n');
    }
  }
}
