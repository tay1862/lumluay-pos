import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { eq, and } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';

@Injectable()
export class PublicService {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  async getMenuBySlug(slug: string) {
    const [tenant] = await this.db
      .select()
      .from(schema.tenants)
      .where(and(eq(schema.tenants.slug, slug), eq(schema.tenants.isActive, true)));

    if (!tenant) throw new NotFoundException('Store not found');

    const categories = await this.db
      .select()
      .from(schema.categories)
      .where(
        and(
          eq(schema.categories.tenantId, tenant.id),
          eq(schema.categories.isActive, true),
        ),
      )
      .orderBy(schema.categories.sortOrder);

    const products = await this.db
      .select()
      .from(schema.products)
      .where(
        and(
          eq(schema.products.tenantId, tenant.id),
          eq(schema.products.isActive, true),
        ),
      )
      .orderBy(schema.products.name);

    return {
      store: {
        name: tenant.name,
        slug: tenant.slug,
        logo: tenant.logoUrl,
        currency: tenant.defaultCurrency,
      },
      categories,
      products,
    };
  }

  async getQueueStatus(tenantId: string) {
    const active = await this.db
      .select({
        ticketNumber: schema.queue.ticketNumber,
        status: schema.queue.status,
        guestCount: schema.queue.guestCount,
        estimatedWaitMinutes: schema.queue.estimatedWaitMinutes,
        createdAt: schema.queue.createdAt,
      })
      .from(schema.queue)
      .where(
        and(
          eq(schema.queue.tenantId, tenantId),
          eq(schema.queue.status, 'waiting'),
        ),
      )
      .orderBy(schema.queue.createdAt)
      .limit(20);

    return { queue: active, serverTime: new Date().toISOString() };
  }

  // ── 17.8.3 — QR Menu Order (no auth) ────────────────────────────────────

  async createQrOrder(
    slug: string,
    body: {
      tableId?: string;
      items: Array<{ productId: string; quantity: number; note?: string }>;
    },
  ) {
    const [tenant] = await this.db
      .select()
      .from(schema.tenants)
      .where(and(eq(schema.tenants.slug, slug), eq(schema.tenants.isActive, true)));

    if (!tenant) throw new NotFoundException('Store not found');
    if (!body.items?.length) throw new BadRequestException('Order must have at least one item');

    // Validate products
    const productIds = body.items.map((i) => i.productId);
    const products = await this.db
      .select()
      .from(schema.products)
      .where(
        and(
          eq(schema.products.tenantId, tenant.id),
          eq(schema.products.isActive, true),
        ),
      );
    const productMap = new Map(products.map((p) => [p.id, p]));

    let subtotal = 0;
    const validatedItems = body.items.map((item) => {
      const product = productMap.get(item.productId);
      if (!product) throw new BadRequestException(`Product ${item.productId} not found`);
      const lineTotal = Number(product.basePrice) * item.quantity;
      subtotal += lineTotal;
      return { ...item, productName: product.name, unitPrice: Number(product.basePrice), lineTotal };
    });

    // Create order as 'draft' (customer-initiated)
    const [order] = await this.db
      .insert(schema.orders)
      .values({
        tenantId: tenant.id,
        receiptNumber: `QR-${Date.now()}`,
        status: 'open',
        orderType: 'dine_in',
        tableId: body.tableId ?? null,
        subtotal: subtotal.toFixed(2),
        totalAmount: subtotal.toFixed(2),
        createdAt: new Date(),
        updatedAt: new Date(),
      } as typeof schema.orders.$inferInsert)
      .returning();

    // Insert order items
    for (const item of validatedItems) {
      await this.db.insert(schema.orderItems).values({
        tenantId: tenant.id,
        orderId: order.id,
        productId: item.productId,
        productName: item.productName,
        quantity: String(item.quantity),
        unitPrice: item.unitPrice.toFixed(2),
        lineTotal: item.lineTotal.toFixed(2),
        note: item.note ?? null,
        status: 'pending',
        createdAt: new Date(),
      } as typeof schema.orderItems.$inferInsert);
    }

    return {
      orderId: order.id,
      receiptNumber: order.receiptNumber,
      status: order.status,
      subtotal,
      items: validatedItems,
    };
  }
}
