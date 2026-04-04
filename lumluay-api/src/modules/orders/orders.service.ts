import {
  Injectable, Inject, NotFoundException, BadRequestException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { eq, and, desc, gte, lt, inArray, sql } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import {
  orders, orderItems, orderItemModifiers,
  products, productVariants, modifierOptions, kitchenTickets, users,
} from '@/database/schema';
import {
  CreateOrderDto,
  AddOrderItemDto,
  ApplyDiscountDto,
  UpdateOrderItemDto,
  SendToKitchenDto,
  VoidOrderDto,
  VoidOrderItemDto,
} from './dto/order.dto';
import { OrderCalculationService } from './order-calculation.service';
import { KitchenGateway } from '@/modules/kitchen/kitchen.gateway';

@Injectable()
export class OrdersService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
    private readonly calculationService: OrderCalculationService,
    private readonly kitchenGateway: KitchenGateway,
  ) {}

  private async nextReceiptNumber(tenantId: string): Promise<string> {
    // Wrap in a transaction with a per-tenant advisory lock to prevent
    // concurrent duplicate receipt numbers (TOCTOU race condition fix).
    return await this.db.transaction(async (tx) => {
      await tx.execute(sql`SELECT pg_advisory_xact_lock(hashtext(${tenantId}))`);

      const now = new Date();
      const datePart = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}`;
      const prefix = `RC-${datePart}-`;

      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const end = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);

      const lastToday = await tx.query.orders.findFirst({
        where: and(
          eq(orders.tenantId, tenantId),
          gte(orders.createdAt, start),
          lt(orders.createdAt, end),
        ),
        orderBy: [desc(orders.createdAt)],
      });

      let seq = 1;
      if (lastToday?.receiptNumber?.startsWith(prefix)) {
        const parts = lastToday.receiptNumber.split('-');
        const parsed = parseInt(parts[parts.length - 1] ?? '0', 10);
        seq = Number.isNaN(parsed) ? 1 : parsed + 1;
      }

      return `${prefix}${String(seq).padStart(4, '0')}`;
    });
  }

  private async verifyManagerPin(
    tenantId: string,
    userId: string,
    pin: string,
  ): Promise<void> {
    const user = await this.db.query.users.findFirst({
      where: and(eq(users.tenantId, tenantId), eq(users.id, userId)),
    });
    if (!user) throw new NotFoundException('User not found');
    if (!['owner', 'manager'].includes(user.role)) {
      throw new BadRequestException('Only owner/manager can perform this action');
    }
    if (!user.pinCode) throw new BadRequestException('PIN is not configured');
    const ok = await bcrypt.compare(pin, user.pinCode);
    if (!ok) throw new BadRequestException('Invalid PIN');
  }

  findAll(
    tenantId: string,
    filters?: { status?: string; limit?: number; offset?: number },
  ) {
    type OrderStatus = typeof schema.orderStatusEnum.enumValues[number];
    const validStatuses = new Set<string>(schema.orderStatusEnum.enumValues);
    const statuses = filters?.status
      ?.split(',')
      .map((s) => s.trim())
      .filter((s): s is OrderStatus => validStatuses.has(s));

    return this.db.query.orders.findMany({
      where: and(
        eq(orders.tenantId, tenantId),
        statuses?.length ? inArray(orders.status, statuses) : undefined,
      ),
      orderBy: [desc(orders.createdAt)],
      limit: filters?.limit ?? 100,
      offset: filters?.offset ?? 0,
      with: {
        table: true,
        staff: { columns: { id: true, displayName: true } },
        items: { with: { modifiers: true } },
      },
    });
  }

  async findOne(tenantId: string, id: string) {
    const order = await this.db.query.orders.findFirst({
      where: and(eq(orders.tenantId, tenantId), eq(orders.id, id)),
      with: {
        table: true,
        staff: { columns: { id: true, displayName: true } },
        items: { with: { product: true, modifiers: true } },
      },
    });
    if (!order) throw new NotFoundException(`Order ${id} not found`);
    return order;
  }

  async create(tenantId: string, staffId: string, dto: CreateOrderDto) {
    const receiptNumber = await this.nextReceiptNumber(tenantId);

    const [order] = await this.db
      .insert(orders)
      .values({
        tenantId,
        staffId,
        receiptNumber,
        orderType: dto.orderType ?? 'dine_in',
        tableId: dto.tableId,
        guestCount: dto.guestCount,
        customerId: dto.customerId,
        note: dto.note,
        status: 'open',
      })
      .returning();

    if (dto.items && dto.items.length > 0) {
      for (const item of dto.items) {
        await this.addItem(tenantId, order.id, item);
      }
    }

    return this.findOne(tenantId, order.id);
  }

  async addItem(tenantId: string, orderId: string, dto: AddOrderItemDto) {
    // Get product and optional variant
    const product = await this.db.query.products.findFirst({
      where: and(eq(products.tenantId, tenantId), eq(products.id, dto.productId)),
    });
    if (!product) throw new NotFoundException(`Product ${dto.productId} not found`);

    let unitPrice = Number(product.basePrice);
    let variantName: string | undefined;

    if (dto.variantId) {
      const variant = await this.db.query.productVariants.findFirst({
        where: eq(productVariants.id, dto.variantId),
      });
      if (variant) {
        unitPrice = Number(variant.price);
        variantName = variant.name;
      }
    }

    // Calculate modifier extras
    let modifierTotal = 0;
    const resolvedModifiers: Array<{ modifierOptionId: string | null; name: string; extraPrice: string; quantity: number }> = [];

    if (dto.modifiers && dto.modifiers.length > 0) {
      for (const mod of dto.modifiers) {
        const option = await this.db.query.modifierOptions.findFirst({
          where: eq(modifierOptions.id, mod.modifierOptionId),
        });
        if (option) {
          const extra = Number(option.extraPrice) * (mod.quantity ?? 1);
          modifierTotal += extra;
          resolvedModifiers.push({
            modifierOptionId: option.id,
            name: option.name,
            extraPrice: option.extraPrice,
            quantity: mod.quantity ?? 1,
          });
        }
      }
    }

    const lineTotal = (unitPrice + modifierTotal) * dto.quantity;

    const [item] = await this.db
      .insert(orderItems)
      .values({
        orderId,
        tenantId,
        productId: dto.productId,
        variantId: dto.variantId,
        productName: product.name,
        variantName,
        quantity: String(dto.quantity),
        unitPrice: String(unitPrice + modifierTotal),
        lineTotal: String(lineTotal),
        note: dto.note,
        courseNumber: dto.courseNumber,
      })
      .returning();

    if (resolvedModifiers.length > 0) {
      await this.db.insert(orderItemModifiers).values(
        resolvedModifiers.map((m) => ({ ...m, orderItemId: item.id })),
      );
    }

    // Recalculate order totals
    await this.calculationService.recalculateOrderTotals(tenantId, orderId);

    return item;
  }

  async updateItem(
    tenantId: string,
    orderId: string,
    itemId: string,
    dto: UpdateOrderItemDto,
  ) {
    await this.findOne(tenantId, orderId);
    const item = await this.db.query.orderItems.findFirst({
      where: and(
        eq(orderItems.tenantId, tenantId),
        eq(orderItems.orderId, orderId),
        eq(orderItems.id, itemId),
      ),
    });
    if (!item) throw new NotFoundException(`Order item ${itemId} not found`);
    if (item.status !== 'pending') {
      throw new BadRequestException('Only pending items can be edited');
    }

    let modifierTotal = 0;
    if (dto.modifiers) {
      await this.db
        .delete(orderItemModifiers)
        .where(eq(orderItemModifiers.orderItemId, itemId));

      const modifierRows: Array<{
        orderItemId: string;
        modifierOptionId: string | null;
        name: string;
        extraPrice: string;
        quantity: number;
      }> = [];

      for (const mod of dto.modifiers) {
        const option = await this.db.query.modifierOptions.findFirst({
          where: eq(modifierOptions.id, mod.modifierOptionId),
        });
        if (!option) continue;
        const q = mod.quantity ?? 1;
        modifierTotal += Number(option.extraPrice) * q;
        modifierRows.push({
          orderItemId: itemId,
          modifierOptionId: option.id,
          name: option.name,
          extraPrice: option.extraPrice,
          quantity: q,
        });
      }

      if (modifierRows.length > 0) {
        await this.db.insert(orderItemModifiers).values(modifierRows);
      }
    }

    const qty = dto.quantity ?? Number(item.quantity);
    const baseUnit = dto.price ?? Number(item.unitPrice);
    const unitPrice = baseUnit + modifierTotal;
    const lineTotal = unitPrice * qty;

    const [updated] = await this.db
      .update(orderItems)
      .set({
        quantity: String(qty),
        note: dto.note ?? item.note,
        unitPrice: String(unitPrice),
        lineTotal: String(lineTotal),
        updatedAt: new Date(),
      })
      .where(eq(orderItems.id, itemId))
      .returning();

    await this.calculationService.recalculateOrderTotals(tenantId, orderId);
    return updated;
  }

  async removeItem(tenantId: string, orderId: string, itemId: string) {
    await this.findOne(tenantId, orderId);
    const item = await this.db.query.orderItems.findFirst({
      where: and(
        eq(orderItems.tenantId, tenantId),
        eq(orderItems.orderId, orderId),
        eq(orderItems.id, itemId),
      ),
    });
    if (!item) throw new NotFoundException(`Order item ${itemId} not found`);
    if (item.status !== 'pending') {
      throw new BadRequestException('Cannot delete item after sending to kitchen');
    }

    await this.db
      .delete(orderItemModifiers)
      .where(eq(orderItemModifiers.orderItemId, itemId));
    await this.db.delete(orderItems).where(eq(orderItems.id, itemId));
    await this.calculationService.recalculateOrderTotals(tenantId, orderId);
  }

  async confirm(tenantId: string, id: string) {
    const order = await this.findOne(tenantId, id);
    if (order.status !== 'open') {
      throw new BadRequestException(`Order is already ${order.status}`);
    }
    const [updated] = await this.db
      .update(orders)
      .set({ status: 'open', updatedAt: new Date() })
      .where(eq(orders.id, id))
      .returning();
    return updated;
  }

  async cancel(tenantId: string, id: string) {
    await this.findOne(tenantId, id);
    const [updated] = await this.db
      .update(orders)
      .set({ status: 'cancelled', updatedAt: new Date() })
      .where(eq(orders.id, id))
      .returning();
    return updated;
  }

  async applyDiscount(tenantId: string, id: string, dto: ApplyDiscountDto) {
    const order = await this.findOne(tenantId, id);

    const subtotal = Number(order.subtotal ?? 0);
    let discountAmount = dto.amount;

    if (dto.type === 'percent') {
      discountAmount = (subtotal * dto.amount) / 100;
    }

    discountAmount = Math.max(0, Math.min(discountAmount, subtotal));

    const extra = {
      ...(order.extra as Record<string, unknown> | null ?? {}),
      discount: {
        type: dto.type ?? 'amount',
        amount: discountAmount,
        couponCode: dto.couponCode,
      },
    };

    await this.db
      .update(orders)
      .set({
        discountAmount: String(discountAmount),
        extra,
        updatedAt: new Date(),
      })
      .where(eq(orders.id, id));
    await this.calculationService.recalculateOrderTotals(tenantId, id);
    return this.findOne(tenantId, id);
  }

  async hold(tenantId: string, id: string) {
    const order = await this.db.query.orders.findFirst({
      where: and(eq(orders.tenantId, tenantId), eq(orders.id, id)),
    });
    if (!order) throw new NotFoundException(`Order ${id} not found`);
    if (order.status === 'completed' || order.status === 'cancelled') {
      throw new BadRequestException('Cannot hold a completed/cancelled order');
    }

    const extra = {
      ...(order.extra as Record<string, unknown> | null ?? {}),
      hold: true,
      heldAt: new Date().toISOString(),
    };

    const [updated] = await this.db
      .update(orders)
      .set({
        status: 'held',
        extra,
        updatedAt: new Date(),
      })
      .where(eq(orders.id, id))
      .returning();

    return updated;
  }

  async resume(tenantId: string, id: string) {
    const order = await this.db.query.orders.findFirst({
      where: and(eq(orders.tenantId, tenantId), eq(orders.id, id)),
    });
    if (!order) throw new NotFoundException(`Order ${id} not found`);

    const oldExtra = (order.extra as Record<string, unknown> | null) ?? {};
    const extra = {
      ...oldExtra,
      hold: false,
      resumedAt: new Date().toISOString(),
    };

    const [updated] = await this.db
      .update(orders)
      .set({
        status: 'open',
        extra,
        updatedAt: new Date(),
      })
      .where(eq(orders.id, id))
      .returning();

    return updated;
  }

  async voidOrder(
    tenantId: string,
    id: string,
    userId: string,
    dto: VoidOrderDto,
  ) {
    const order = await this.findOne(tenantId, id);
    await this.verifyManagerPin(tenantId, userId, dto.pin);

    const extra = {
      ...(order.extra as Record<string, unknown> | null ?? {}),
      voidReason: dto.reason,
      voidedAt: new Date().toISOString(),
      voidedBy: userId,
    };

    const [updated] = await this.db
      .update(orders)
      .set({
        status: 'cancelled',
        note: order.note ? `${order.note}\n[VOID] ${dto.reason}` : `[VOID] ${dto.reason}`,
        extra,
        updatedAt: new Date(),
      })
      .where(eq(orders.id, id))
      .returning();

    await this.db
      .update(orderItems)
      .set({ status: 'cancelled', updatedAt: new Date() })
      .where(eq(orderItems.orderId, id));

    return updated;
  }

  async voidOrderItem(
    tenantId: string,
    id: string,
    userId: string,
    dto: VoidOrderItemDto,
  ) {
    await this.findOne(tenantId, id);
    await this.verifyManagerPin(tenantId, userId, dto.pin);

    const item = await this.db.query.orderItems.findFirst({
      where: and(
        eq(orderItems.tenantId, tenantId),
        eq(orderItems.orderId, id),
        eq(orderItems.id, dto.itemId),
      ),
    });
    if (!item) throw new NotFoundException(`Order item ${dto.itemId} not found`);

    const [updated] = await this.db
      .update(orderItems)
      .set({
        status: 'cancelled',
        lineTotal: '0',
        note: item.note ? `${item.note}\n[VOID] ${dto.reason}` : `[VOID] ${dto.reason}`,
        updatedAt: new Date(),
      })
      .where(eq(orderItems.id, dto.itemId))
      .returning();

    await this.calculationService.recalculateOrderTotals(tenantId, id);
    return updated;
  }

  async sendToKitchen(tenantId: string, id: string, dto: SendToKitchenDto) {
    await this.findOne(tenantId, id);
    const items = await this.db.query.orderItems.findMany({
      where: and(
        eq(orderItems.orderId, id),
        eq(orderItems.tenantId, tenantId),
        eq(orderItems.status, 'pending'),
        dto.itemIds && dto.itemIds.length > 0
          ? inArray(orderItems.id, dto.itemIds)
          : undefined,
      ),
    });

    if (items.length === 0) {
      throw new BadRequestException('No pending items to send');
    }

    await this.db.insert(kitchenTickets).values(
      items.map((item: typeof items[number]) => ({
        tenantId,
        orderItemId: item.id,
        station: dto.station,
        note: item.note,
        status: 'pending' as const,
      })),
    );

    this.kitchenGateway.emitNewOrder(tenantId, {
      orderId: id,
      station: dto.station,
      itemIds: items.map((item) => item.id),
      itemCount: items.length,
    });

    await this.db
      .update(orderItems)
      .set({ status: 'preparing', updatedAt: new Date() })
      .where(
        and(
          eq(orderItems.orderId, id),
          eq(orderItems.tenantId, tenantId),
          dto.itemIds && dto.itemIds.length > 0
            ? inArray(orderItems.id, dto.itemIds)
            : undefined,
        ),
      );

    await this.db
      .update(orders)
      .set({
        status: 'preparing',
        updatedAt: new Date(),
      })
      .where(eq(orders.id, id));

    return { success: true, sentCount: items.length };
  }
}
