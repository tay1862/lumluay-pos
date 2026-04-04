import {
  Injectable, Inject, NotFoundException, BadRequestException,
} from '@nestjs/common';
import { eq, and, asc, inArray } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import {
  tables,
  zones,
  orders,
  orderItems,
  tenants,
} from '@/database/schema';
import { OrderCalculationService } from '@/modules/orders/order-calculation.service';

export interface CreateTableDto {
  zoneId?: string;
  name: string;
  capacity?: number;
  posX?: number;
  posY?: number;
}

export interface CreateZoneDto {
  name: string;
  description?: string;
  sortOrder?: number;
}

export interface UpdateZoneDto {
  name?: string;
  description?: string;
  sortOrder?: number;
  isActive?: boolean;
}
export interface UpdateTableDto {
  name?: string;
  capacity?: number;
  status?: 'available' | 'occupied' | 'reserved' | 'cleaning';
  posX?: number;
  posY?: number;
  isActive?: boolean;
}

export interface MoveTableDto {
  targetTableId?: string;
  target_table_id?: string;
}

export interface MergeTablesDto {
  targetTableId?: string;
  target_table_id?: string;
  mergeTableIds?: string[];
  merge_table_ids?: string[];
}

export interface SplitTableDto {
  targetTableId?: string;
  target_table_id?: string;
  orderItemIds?: string[];
  order_item_ids?: string[];
}

@Injectable()
export class TablesService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
    private readonly orderCalculationService: OrderCalculationService,
  ) {}

  private readonly activeOrderStatuses: Array<typeof orders.$inferSelect.status> = [
    'open',
    'held',
    'preparing',
    'ready',
    'served',
  ];

  private async findActiveOrderByTable(tenantId: string, tableId: string) {
    return this.db.query.orders.findFirst({
      where: and(
        eq(orders.tenantId, tenantId),
        eq(orders.tableId, tableId),
        inArray(orders.status, this.activeOrderStatuses),
      ),
      orderBy: [asc(orders.createdAt)],
    });
  }

  findAll(tenantId: string) {
    return this.db.query.tables.findMany({
      where: and(eq(tables.tenantId, tenantId), eq(tables.isActive, true)),
      orderBy: [asc(tables.name)],
      with: { zone: true },
    });
  }

  findZones(tenantId: string) {
    return this.db.query.zones.findMany({
      where: and(eq(zones.tenantId, tenantId), eq(zones.isActive, true)),
      orderBy: [asc(zones.sortOrder), asc(zones.name)],
      with: { tables: { where: eq(tables.isActive, true) } },
    });
  }

  async findZone(tenantId: string, id: string) {
    const zone = await this.db.query.zones.findFirst({
      where: and(eq(zones.tenantId, tenantId), eq(zones.id, id)),
      with: { tables: { where: eq(tables.isActive, true) } },
    });
    if (!zone) throw new NotFoundException(`Zone ${id} not found`);
    return zone;
  }

  async createZone(tenantId: string, dto: CreateZoneDto) {
    const [zone] = await this.db.insert(zones).values({
      tenantId,
      name: dto.name,
      description: dto.description,
      sortOrder: dto.sortOrder ?? 0,
    }).returning();
    return zone;
  }

  async updateZone(tenantId: string, id: string, dto: UpdateZoneDto) {
    const existing = await this.db.query.zones.findFirst({
      where: and(eq(zones.tenantId, tenantId), eq(zones.id, id)),
    });
    if (!existing) throw new NotFoundException(`Zone ${id} not found`);

    const [updated] = await this.db
      .update(zones)
      .set({ ...dto, updatedAt: new Date() })
      .where(and(eq(zones.tenantId, tenantId), eq(zones.id, id)))
      .returning();
    return updated;
  }

  async deleteZone(tenantId: string, id: string) {
    const existing = await this.db.query.zones.findFirst({
      where: and(eq(zones.tenantId, tenantId), eq(zones.id, id)),
    });
    if (!existing) throw new NotFoundException(`Zone ${id} not found`);

    const zoneTables = await this.db.query.tables.findMany({
      where: and(eq(tables.tenantId, tenantId), eq(tables.zoneId, id), eq(tables.isActive, true)),
    });

    if (zoneTables.length > 0) {
      throw new BadRequestException('Cannot delete zone with active tables');
    }

    await this.db
      .delete(zones)
      .where(and(eq(zones.tenantId, tenantId), eq(zones.id, id)));

    return { deleted: true, id };
  }

  async findOne(tenantId: string, id: string) {
    const table = await this.db.query.tables.findFirst({
      where: and(eq(tables.tenantId, tenantId), eq(tables.id, id)),
      with: { zone: true },
    });
    if (!table) throw new NotFoundException(`Table ${id} not found`);
    return table;
  }

  async create(tenantId: string, dto: CreateTableDto) {
    const [table] = await this.db.insert(tables).values({ tenantId, ...dto }).returning();
    return table;
  }

  async update(tenantId: string, id: string, dto: UpdateTableDto) {
    await this.findOne(tenantId, id);
    const [updated] = await this.db
      .update(tables)
      .set({ ...dto, updatedAt: new Date() })
      .where(and(eq(tables.tenantId, tenantId), eq(tables.id, id)))
      .returning();
    return updated;
  }

  async setStatus(tenantId: string, id: string, status: 'available' | 'occupied' | 'reserved' | 'cleaning') {
    await this.findOne(tenantId, id);
    const [updated] = await this.db
      .update(tables)
      .set({ status, updatedAt: new Date() })
      .where(and(eq(tables.tenantId, tenantId), eq(tables.id, id)))
      .returning();
    return updated;
  }

  async moveTable(tenantId: string, sourceTableId: string, dto: MoveTableDto) {
    const targetTableId = dto.targetTableId ?? dto.target_table_id;
    if (!targetTableId) {
      throw new BadRequestException('targetTableId is required');
    }
    if (targetTableId === sourceTableId) {
      throw new BadRequestException('targetTableId must be different from source table');
    }

    await this.findOne(tenantId, sourceTableId);
    await this.findOne(tenantId, targetTableId);

    const [sourceOrder, targetOrder] = await Promise.all([
      this.findActiveOrderByTable(tenantId, sourceTableId),
      this.findActiveOrderByTable(tenantId, targetTableId),
    ]);

    if (!sourceOrder) {
      throw new NotFoundException('No active order on source table');
    }
    if (targetOrder) {
      throw new BadRequestException('Target table already has an active order');
    }

    const [movedOrder] = await this.db
      .update(orders)
      .set({ tableId: targetTableId, updatedAt: new Date() })
      .where(and(eq(orders.tenantId, tenantId), eq(orders.id, sourceOrder.id)))
      .returning();

    await this.db
      .update(tables)
      .set({ status: 'available', updatedAt: new Date() })
      .where(and(eq(tables.tenantId, tenantId), eq(tables.id, sourceTableId)));

    await this.db
      .update(tables)
      .set({ status: 'occupied', updatedAt: new Date() })
      .where(and(eq(tables.tenantId, tenantId), eq(tables.id, targetTableId)));

    return {
      sourceTableId,
      targetTableId,
      orderId: movedOrder.id,
      moved: true,
    };
  }

  async mergeTables(tenantId: string, dto: MergeTablesDto) {
    const targetTableId = dto.targetTableId ?? dto.target_table_id;
    const mergeTableIds = dto.mergeTableIds ?? dto.merge_table_ids ?? [];

    if (!targetTableId) {
      throw new BadRequestException('targetTableId is required');
    }

    const normalizedMergeIds = Array.from(
      new Set(mergeTableIds.filter((id) => !!id && id !== targetTableId)),
    );
    if (normalizedMergeIds.length === 0) {
      throw new BadRequestException('mergeTableIds is required');
    }

    await this.findOne(tenantId, targetTableId);
    for (const tableId of normalizedMergeIds) {
      await this.findOne(tenantId, tableId);
    }

    const targetOrder = await this.findActiveOrderByTable(tenantId, targetTableId);
    const sourceOrders = await Promise.all(
      normalizedMergeIds.map((tableId) => this.findActiveOrderByTable(tenantId, tableId)),
    );
    const nonNullSourceOrders = sourceOrders.filter(
      (
        o: unknown,
      ): o is NonNullable<Awaited<ReturnType<TablesService['findActiveOrderByTable']>>> => !!o,
    );

    if (!targetOrder && nonNullSourceOrders.length === 0) {
      throw new BadRequestException('No active orders to merge');
    }

    let baseOrder = targetOrder;
    const consumedOrderIds: string[] = [];

    if (!baseOrder) {
      baseOrder = nonNullSourceOrders[0];
      if (!baseOrder) {
        throw new BadRequestException('No source order found');
      }
      await this.db
        .update(orders)
        .set({ tableId: targetTableId, updatedAt: new Date() })
        .where(and(eq(orders.tenantId, tenantId), eq(orders.id, baseOrder.id)));
    }

    for (const sourceOrder of nonNullSourceOrders) {
      if (sourceOrder.id === baseOrder.id) continue;
      if (Number(sourceOrder.paidAmount ?? 0) > 0) {
        throw new BadRequestException(
          `Cannot merge order ${sourceOrder.id}: partially paid order is not supported`,
        );
      }

      await this.db
        .update(orderItems)
        .set({ orderId: baseOrder.id, updatedAt: new Date() })
        .where(and(eq(orderItems.tenantId, tenantId), eq(orderItems.orderId, sourceOrder.id)));

      await this.db
        .update(orders)
        .set({
          status: 'cancelled',
          note: sourceOrder.note
            ? `${sourceOrder.note}\n[MERGED] into ${baseOrder.receiptNumber}`
            : `[MERGED] into ${baseOrder.receiptNumber}`,
          updatedAt: new Date(),
        })
        .where(and(eq(orders.tenantId, tenantId), eq(orders.id, sourceOrder.id)));

      consumedOrderIds.push(sourceOrder.id);
    }

    await this.orderCalculationService.recalculateOrderTotals(tenantId, baseOrder.id);

    await this.db
      .update(tables)
      .set({ status: 'occupied', updatedAt: new Date() })
      .where(and(eq(tables.tenantId, tenantId), eq(tables.id, targetTableId)));

    await this.db
      .update(tables)
      .set({ status: 'reserved', updatedAt: new Date() })
      .where(and(eq(tables.tenantId, tenantId), inArray(tables.id, normalizedMergeIds)));

    return {
      targetTableId,
      baseOrderId: baseOrder.id,
      mergedFromTableIds: normalizedMergeIds,
      consumedOrderIds,
      merged: true,
    };
  }

  async splitTable(tenantId: string, sourceTableId: string, dto: SplitTableDto) {
    const targetTableId = dto.targetTableId ?? dto.target_table_id;
    const orderItemIds = dto.orderItemIds ?? dto.order_item_ids ?? [];

    if (!targetTableId) {
      throw new BadRequestException('targetTableId is required');
    }
    if (targetTableId === sourceTableId) {
      throw new BadRequestException('targetTableId must be different from source table');
    }
    if (orderItemIds.length === 0) {
      throw new BadRequestException('orderItemIds is required');
    }

    await this.findOne(tenantId, sourceTableId);
    await this.findOne(tenantId, targetTableId);

    const sourceOrder = await this.findActiveOrderByTable(tenantId, sourceTableId);
    if (!sourceOrder) {
      throw new NotFoundException('No active order on source table');
    }

    const targetOrder = await this.findActiveOrderByTable(tenantId, targetTableId);
    if (targetOrder) {
      throw new BadRequestException('Target table already has an active order');
    }

    const itemsToMove = await this.db.query.orderItems.findMany({
      where: and(
        eq(orderItems.tenantId, tenantId),
        eq(orderItems.orderId, sourceOrder.id),
        inArray(orderItems.id, orderItemIds),
      ),
    });

    if (itemsToMove.length === 0) {
      throw new BadRequestException('No matching order items to split');
    }
    if (itemsToMove.length !== orderItemIds.length) {
      throw new BadRequestException('Some order items are invalid for this order');
    }

    const splitReceipt = `${sourceOrder.receiptNumber}-S${Date.now().toString().slice(-4)}`;
    const [splitOrder] = await this.db
      .insert(orders)
      .values({
        tenantId,
        receiptNumber: splitReceipt,
        orderType: sourceOrder.orderType,
        status: 'open',
        tableId: targetTableId,
        customerId: sourceOrder.customerId,
        staffId: sourceOrder.staffId,
        guestCount: sourceOrder.guestCount,
        note: sourceOrder.note,
        subtotal: '0',
        discountAmount: '0',
        taxAmount: '0',
        serviceChargeAmount: '0',
        totalAmount: '0',
        paidAmount: '0',
        changeAmount: '0',
        isTrainingMode: sourceOrder.isTrainingMode,
        extra: {
          ...(sourceOrder.extra as Record<string, unknown> | null ?? {}),
          splitFromOrderId: sourceOrder.id,
          splitAt: new Date().toISOString(),
        },
        updatedAt: new Date(),
      })
      .returning();

    await this.db
      .update(orderItems)
      .set({ orderId: splitOrder.id, updatedAt: new Date() })
      .where(and(eq(orderItems.tenantId, tenantId), inArray(orderItems.id, orderItemIds)));

    await this.orderCalculationService.recalculateOrderTotals(tenantId, sourceOrder.id);
    await this.orderCalculationService.recalculateOrderTotals(tenantId, splitOrder.id);

    const remainingItems = await this.db.query.orderItems.findMany({
      where: and(eq(orderItems.tenantId, tenantId), eq(orderItems.orderId, sourceOrder.id)),
    });

    if (remainingItems.length === 0) {
      await this.db
        .update(tables)
        .set({ status: 'available', updatedAt: new Date() })
        .where(and(eq(tables.tenantId, tenantId), eq(tables.id, sourceTableId)));
    }

    await this.db
      .update(tables)
      .set({ status: 'occupied', updatedAt: new Date() })
      .where(and(eq(tables.tenantId, tenantId), eq(tables.id, targetTableId)));

    return {
      sourceTableId,
      targetTableId,
      sourceOrderId: sourceOrder.id,
      splitOrderId: splitOrder.id,
      movedItemCount: itemsToMove.length,
      split: true,
    };
  }

  async generateTableQrCode(tenantId: string, tableId: string) {
    const table = await this.findOne(tenantId, tableId);
    const tenant = await this.db.query.tenants.findFirst({
      where: and(eq(tenants.id, tenantId), eq(tenants.isActive, true)),
    });
    if (!tenant) {
      throw new NotFoundException(`Tenant ${tenantId} not found`);
    }

    const baseUrl = (process.env.PUBLIC_MENU_BASE_URL ?? 'https://menu.lumluay.com').replace(/\/$/, '');
    const url = `${baseUrl}/${tenant.slug}/${table.id}`;

    return {
      tableId: table.id,
      tableName: table.name,
      tenantSlug: tenant.slug,
      url,
      qrPayload: url,
    };
  }
}
