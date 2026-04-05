import {
  Injectable, Inject, NotFoundException, BadRequestException,
} from '@nestjs/common';
import { eq, and, desc, sql } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import { payments, orders, orderItems, stockLevels, stockMovements, members, products } from '@/database/schema';
import {
  CreatePaymentDto,
  SplitPaymentDto,
  CompleteOrderDto,
  RefundOrderDto,
} from './dto/payment.dto';
import { ExchangeRateService } from './exchange-rate.service';
import { NotificationsService } from '@/modules/notifications/notifications.service';
import { CouponsService } from '@/modules/coupons/coupons.service';

@Injectable()
export class PaymentsService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
    private readonly exchangeRateService: ExchangeRateService,
    private readonly notificationsService: NotificationsService,
    private readonly couponsService: CouponsService,
  ) {}

  findByOrder(tenantId: string, orderId: string) {
    return this.db.query.payments.findMany({
      where: and(eq(payments.tenantId, tenantId), eq(payments.orderId, orderId)),
      orderBy: [desc(payments.createdAt)],
    });
  }

  private async findOrderForPayment(tenantId: string, orderId: string) {
    const order = await this.db.query.orders.findFirst({
      where: and(eq(orders.tenantId, tenantId), eq(orders.id, orderId)),
    });
    if (!order) throw new NotFoundException(`Order ${orderId} not found`);
    if (order.status === 'completed' || order.status === 'cancelled') {
      throw new BadRequestException(`Order is already ${order.status}`);
    }
    return order;
  }

  private async getPaidTotal(tenantId: string, orderId: string): Promise<number> {
    const list = await this.db.query.payments.findMany({
      where: and(eq(payments.tenantId, tenantId), eq(payments.orderId, orderId)),
    });
    return list.reduce((sum, p) => sum + Number(p.amount), 0);
  }

  async create(
    tenantId: string,
    cashierId: string,
    orderId: string,
    dto: CreatePaymentDto,
  ) {
    if (!orderId) {
      throw new BadRequestException('orderId is required');
    }

    const order = await this.findOrderForPayment(tenantId, orderId);

    const baseCurrency = await this.exchangeRateService.getBaseCurrency(tenantId);
    const currency = (dto.currency ?? baseCurrency).toUpperCase();
    const amount = dto.amount;
    const tendered = dto.tendered ?? amount;

    const { baseAmount, rate } = await this.exchangeRateService.toBase(
      tenantId,
      amount,
      currency,
      dto.exchangeRate,
    );

    const paidBefore = await this.getPaidTotal(tenantId, orderId);
    const remainingBefore = Math.max(
      0,
      Math.round((Number(order.totalAmount) - paidBefore) * 100) / 100,
    );

    const isBaseCurrency = currency === baseCurrency;
    const dueInCurrency = isBaseCurrency
      ? remainingBefore
      : remainingBefore / (rate || 1);
    const rawChange = Math.max(0, tendered - dueInCurrency);
    const changeInCurrency = Math.round(rawChange * 100) / 100;
    const changeInBase = isBaseCurrency
      ? changeInCurrency
      : Math.round((changeInCurrency * (rate || 1)) * 100) / 100;

    const paidAfter = Math.round((paidBefore + baseAmount) * 100) / 100;
    const remaining = Math.max(0, Math.round((Number(order.totalAmount) - paidAfter) * 100) / 100);

    const [payment] = await this.db
      .insert(payments)
      .values({
        tenantId,
        orderId,
        cashierId,
        method: dto.method as typeof payments.$inferInsert['method'],
        status: 'completed',
        amount: String(baseAmount),
        tendered: String(tendered),
        change: String(changeInBase),
        reference: dto.reference,
        note: dto.note,
        extra: {
          currency,
          exchangeRate: rate,
          sourceAmount: amount,
          changeInCurrency,
        },
        updatedAt: new Date(),
      })
      .returning();

    await this.db
      .update(orders)
      .set({
        paidAmount: String(paidAfter),
        changeAmount: String(changeInBase),
        updatedAt: new Date(),
      })
      .where(eq(orders.id, orderId));

    return {
      payment,
      split: {
        paidBefore,
        paidAfter,
        total: Number(order.totalAmount),
        remaining,
      },
      change: {
        base: changeInBase,
        currency,
        amount: changeInCurrency,
      },
    };
  }

  // ─── Split Payment (batch) ───────────────────────────────────────────────
  async splitPayment(
    tenantId: string,
    cashierId: string,
    orderId: string,
    dto: SplitPaymentDto,
  ) {
    const order = await this.findOrderForPayment(tenantId, orderId);
    const total = Number(order.totalAmount);
    const paidBefore = await this.getPaidTotal(tenantId, orderId);
    const remainingBefore = Math.max(0, this.round2(total - paidBefore));
    const baseCurrency = await this.exchangeRateService.getBaseCurrency(tenantId);

    // Validate that the sum of payment amounts covers the remaining balance
    const sumBase: number[] = [];
    for (const item of dto.payments) {
      const currency = (item.currency ?? baseCurrency).toUpperCase();
      const { baseAmount } = await this.exchangeRateService.toBase(
        tenantId,
        item.amount,
        currency,
        item.exchangeRate,
      );
      sumBase.push(baseAmount);
    }
    const totalSubmitted = this.round2(sumBase.reduce((a, b) => a + b, 0));
    if (totalSubmitted < remainingBefore) {
      throw new BadRequestException(
        `Insufficient split payment: submitted ${totalSubmitted.toFixed(2)} < remaining ${remainingBefore.toFixed(2)}`,
      );
    }

    // Process each payment
    const results: Array<Awaited<ReturnType<typeof this.create>>> = [];
    for (const item of dto.payments) {
      const singleDto: CreatePaymentDto = {
        method: item.method,
        amount: item.amount,
        tendered: item.tendered,
        reference: item.reference,
        note: item.note,
        currency: item.currency,
        exchangeRate: item.exchangeRate,
      };
      const result = await this.create(tenantId, cashierId, orderId, singleDto);
      results.push(result);
    }

    const lastResult = results[results.length - 1];
    const paidAfter = lastResult.split.paidAfter;
    const remaining = lastResult.split.remaining;

    // Auto-complete if requested and fully paid
    let completedOrder: Awaited<ReturnType<typeof this.completeOrder>> | null = null;
    if (dto.autoComplete !== false && remaining <= 0) {
      completedOrder = await this.completeOrder(tenantId, orderId);
    }

    return {
      payments: results.map((r) => r.payment),
      summary: {
        total,
        paidBefore,
        paidAfter,
        remaining,
        paymentCount: results.length,
        change: lastResult.change,
      },
      completed: completedOrder !== null,
      order: completedOrder?.order ?? null,
    };
  }

  private round2(value: number): number {
    return Math.round(value * 100) / 100;
  }

  async completeOrder(tenantId: string, orderId: string, _dto?: CompleteOrderDto) {
    const order = await this.db.query.orders.findFirst({
      where: and(eq(orders.tenantId, tenantId), eq(orders.id, orderId)),
    });
    if (!order) throw new NotFoundException(`Order ${orderId} not found`);

    const paid = await this.getPaidTotal(tenantId, orderId);
    const total = Number(order.totalAmount);
    if (paid < total) {
      throw new BadRequestException(
        `Insufficient payment: paid ${paid.toFixed(2)} < total ${total.toFixed(2)}`,
      );
    }

    const change = Math.max(0, Math.round((paid - total) * 100) / 100);

    const [updated] = await this.db
      .update(orders)
      .set({
        status: 'completed',
        paidAmount: String(Math.round(paid * 100) / 100),
        changeAmount: String(change),
        completedAt: new Date(),
        updatedAt: new Date(),
      })
      .where(eq(orders.id, orderId))
      .returning();

    // 11.1.5 — Auto stock deduction
    await this.deductStock(tenantId, orderId);

    // 12.1.4 — Member stats update
    if (order.customerId) {
      await this.updateMemberStats(tenantId, order.customerId, Number(order.totalAmount));
    }

    // 13.1.4 — Coupon usage increment
    const orderExtra = order.extra as Record<string, unknown> | null;
    const couponCode = (orderExtra?.discount as Record<string, unknown> | undefined)?.couponCode as string | undefined;
    if (couponCode) {
      try {
        const coupon = await this.couponsService.findByCode(tenantId, couponCode);
        await this.couponsService.incrementUsage(coupon.id);
      } catch {
        // ignore if coupon not found (already deleted)
      }
    }

    return { order: updated, paid, total, change };
  }

  // ─── 11.1.5 Auto Stock Deduction ───────────────────────────────────────────
  private async deductStock(tenantId: string, orderId: string) {
    const items = await this.db.query.orderItems.findMany({
      where: and(eq(orderItems.orderId, orderId)),
      with: { product: true },
    });

    for (const item of items) {
      const product = item.product;
      if (!product || !product.trackStock) continue;

      const deductQty = -Number(item.quantity);

      const current = await this.db.query.stockLevels.findFirst({
        where: and(
          eq(stockLevels.tenantId, tenantId),
          eq(stockLevels.productId, item.productId),
        ),
      });

      const balanceBefore = current ? Number(current.quantity) : 0;
      const balanceAfter = balanceBefore + deductQty;

      if (current) {
        await this.db
          .update(stockLevels)
          .set({ quantity: String(balanceAfter), updatedAt: new Date() })
          .where(eq(stockLevels.id, current.id));
      } else {
        await this.db.insert(stockLevels).values({
          tenantId,
          productId: item.productId,
          quantity: String(balanceAfter),
        });
      }

      await this.db.insert(stockMovements).values({
        tenantId,
        productId: item.productId,
        type: 'sale',
        quantity: String(deductQty),
        balanceBefore: String(balanceBefore),
        balanceAfter: String(balanceAfter),
        note: `Auto-deducted from order ${orderId}`,
      });

      // Check low-stock threshold and create notification
      const lowThreshold = Number(
        (product.extra as Record<string, unknown> | null)?.['lowStockThreshold'] ?? 0,
      );
      if (lowThreshold > 0 && balanceAfter <= lowThreshold) {
        await this.notificationsService.create(tenantId, {
          type: 'low_stock',
          title: 'ສິນຄ້າໃກ້ໝົດ',
          body: `${product.name} ເຫຼືອ ${balanceAfter} ${product.unit ?? 'ຊິ້ນ'}`,
          data: { productId: item.productId, quantity: balanceAfter },
        });
      }
    }
  }

  // ─── 12.1.4 Member Stats Update ────────────────────────────────────────────
  private async updateMemberStats(
    tenantId: string,
    memberId: string,
    orderTotal: number,
  ) {
    await this.db
      .update(members)
      .set({
        totalSpent: sql`${members.totalSpent} + ${String(orderTotal)}`,
        visitCount: sql`${members.visitCount} + 1`,
        updatedAt: new Date(),
      })
      .where(
        and(eq(members.id, memberId), eq(members.tenantId, tenantId)),
      );
  }

  async refundOrder(
    tenantId: string,
    cashierId: string,
    orderId: string,
    dto: RefundOrderDto,
  ) {
    const order = await this.db.query.orders.findFirst({
      where: and(eq(orders.tenantId, tenantId), eq(orders.id, orderId)),
    });
    if (!order) throw new NotFoundException(`Order ${orderId} not found`);
    if (order.status !== 'completed') {
      throw new BadRequestException('Only completed orders can be refunded');
    }

    const originalPayments = await this.db.query.payments.findMany({
      where: and(eq(payments.tenantId, tenantId), eq(payments.orderId, orderId)),
      orderBy: [desc(payments.createdAt)],
    });
    if (originalPayments.length === 0) {
      throw new BadRequestException('No payment found to refund');
    }

    const refundable = originalPayments
      .filter((p) => p.status === 'completed')
      .reduce((sum, p) => sum + Number(p.amount), 0);

    const requested = dto.amount ?? refundable;
    if (requested <= 0 || requested > refundable) {
      throw new BadRequestException('Invalid refund amount');
    }

    const now = new Date();
    const originalExtra =
      (order.extra as Record<string, unknown> | null | undefined) ?? {};

    const [refundOrder] = await this.db
      .insert(orders)
      .values({
        tenantId,
        receiptNumber: `${order.receiptNumber}-RF`,
        orderType: order.orderType,
        status: 'refunded',
        tableId: order.tableId,
        customerId: order.customerId,
        staffId: cashierId,
        guestCount: order.guestCount,
        note: dto.reason ?? 'Refund',
        subtotal: String(-requested),
        discountAmount: '0',
        taxAmount: '0',
        serviceChargeAmount: '0',
        totalAmount: String(-requested),
        paidAmount: String(-requested),
        changeAmount: '0',
        isTrainingMode: order.isTrainingMode,
        extra: {
          ...originalExtra,
          refundOfOrderId: order.id,
          refundReason: dto.reason,
          refundAmount: requested,
        },
        completedAt: now,
        updatedAt: now,
      })
      .returning();

    await this.db
      .insert(payments)
      .values({
        tenantId,
        orderId: refundOrder.id,
        cashierId,
        method: originalPayments[0].method,
        status: 'refunded',
        amount: String(-requested),
        tendered: String(0),
        change: String(0),
        note: dto.reason ?? 'Refund',
        extra: {
          originalOrderId: order.id,
          originalPaymentIds: originalPayments.map((p) => p.id),
        },
        updatedAt: now,
      });

    const status = requested < refundable ? 'partially_refunded' : 'refunded';

    await this.db
      .update(payments)
      .set({ status, updatedAt: now })
      .where(and(eq(payments.tenantId, tenantId), eq(payments.orderId, orderId)));

    await this.db
      .update(orders)
      .set({
        status: 'refunded',
        updatedAt: now,
        extra: {
          ...originalExtra,
          refundedAmount: requested,
          refundedAt: now.toISOString(),
          refundOrderId: refundOrder.id,
        },
      })
      .where(eq(orders.id, orderId));

    return {
      refundOrder,
      refundedAmount: requested,
      originalOrderId: orderId,
      partial: requested < refundable,
    };
  }
}
