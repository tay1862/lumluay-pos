import { Injectable, Inject } from '@nestjs/common';
import { and, eq } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import { orderItems, orders, storeSettings, taxRates } from '@/database/schema';

@Injectable()
export class OrderCalculationService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  private round2(value: number): number {
    return Math.round(value * 100) / 100;
  }

  async recalculateOrderTotals(tenantId: string, orderId: string): Promise<void> {
    const [order, settings, items] = await Promise.all([
      this.db.query.orders.findFirst({ where: eq(orders.id, orderId) }),
      this.db.query.storeSettings.findFirst({
        where: eq(storeSettings.tenantId, tenantId),
      }),
      this.db.query.orderItems.findMany({ where: eq(orderItems.orderId, orderId) }),
    ]);

    if (!order) return;

    const subtotal = this.round2(
      items.reduce(
        (sum: number, item: typeof items[number]) => sum + Number(item.lineTotal),
        0,
      ),
    );

    const discount = Math.max(0, Number(order.discountAmount ?? 0));
    const afterDiscount = Math.max(0, subtotal - discount);

    const servicePercent = settings?.serviceChargeEnabled
      ? Number(settings.serviceChargePercent ?? 0)
      : 0;
    const serviceChargeAmount = this.round2((afterDiscount * servicePercent) / 100);

    let taxPercent = 0;
    if (settings?.defaultTaxRateId) {
      const tax = await this.db.query.taxRates.findFirst({
        where: and(
          eq(taxRates.tenantId, tenantId),
          eq(taxRates.id, settings.defaultTaxRateId),
          eq(taxRates.isActive, true),
        ),
      });
      taxPercent = Number(tax?.rate ?? 0);
    }

    const taxBase = Math.max(0, afterDiscount + serviceChargeAmount);
    const taxIncluded = settings?.taxIncluded ?? true;

    let taxAmount = 0;
    let total = taxBase;

    if (taxPercent > 0) {
      if (taxIncluded) {
        taxAmount = this.round2(taxBase - taxBase / (1 + taxPercent / 100));
      } else {
        taxAmount = this.round2((taxBase * taxPercent) / 100);
        total = this.round2(taxBase + taxAmount);
      }
    }

    await this.db
      .update(orders)
      .set({
        subtotal: String(subtotal),
        serviceChargeAmount: String(serviceChargeAmount),
        taxAmount: String(taxAmount),
        totalAmount: String(this.round2(total)),
        updatedAt: new Date(),
      })
      .where(eq(orders.id, orderId));
  }
}
