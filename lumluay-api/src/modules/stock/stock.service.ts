import { Injectable, Inject } from '@nestjs/common';
import { eq, and, desc } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import { stockLevels, stockMovements } from '@/database/schema';

export interface AdjustStockDto {
  productId: string;
  variantId?: string;
  quantity: number;
  type: 'adjustment' | 'purchase' | 'waste' | 'return';
  note?: string;
}

@Injectable()
export class StockService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  findLevels(tenantId: string) {
    return this.db.query.stockLevels.findMany({
      where: eq(stockLevels.tenantId, tenantId),
      with: { product: true },
    });
  }

  findMovements(tenantId: string) {
    return this.db.query.stockMovements.findMany({
      where: eq(stockMovements.tenantId, tenantId),
      orderBy: [desc(stockMovements.createdAt)],
      with: { product: true },
    });
  }

  async adjust(tenantId: string, userId: string, dto: AdjustStockDto) {
    // Get current level
    const current = await this.db.query.stockLevels.findFirst({
      where: and(
        eq(stockLevels.tenantId, tenantId),
        eq(stockLevels.productId, dto.productId),
      ),
    });

    const balanceBefore = current ? Number(current.quantity) : 0;
    const balanceAfter = balanceBefore + dto.quantity;

    // Upsert stock level
    if (current) {
      await this.db
        .update(stockLevels)
        .set({ quantity: String(balanceAfter), updatedAt: new Date() })
        .where(eq(stockLevels.id, current.id));
    } else {
      await this.db.insert(stockLevels).values({
        tenantId,
        productId: dto.productId,
        variantId: dto.variantId,
        quantity: String(balanceAfter),
      });
    }

    // Record movement
    const [movement] = await this.db
      .insert(stockMovements)
      .values({
        tenantId,
        productId: dto.productId,
        variantId: dto.variantId,
        type: dto.type,
        quantity: String(dto.quantity),
        balanceBefore: String(balanceBefore),
        balanceAfter: String(balanceAfter),
        userId,
        note: dto.note,
      })
      .returning();

    return movement;
  }
}
