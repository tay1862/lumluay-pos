import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { eq, and, desc, gte, lte } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';
import { OpenShiftDto, CloseShiftDto } from './dto/shift.dto';

@Injectable()
export class ShiftsService {
  constructor(@InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>) {}

  async findAll(tenantId: string) {
    return this.db
      .select()
      .from(schema.shifts)
      .where(eq(schema.shifts.tenantId, tenantId))
      .orderBy(desc(schema.shifts.openedAt));
  }

  async findOne(tenantId: string, id: string) {
    const [shift] = await this.db
      .select()
      .from(schema.shifts)
      .where(and(eq(schema.shifts.id, id), eq(schema.shifts.tenantId, tenantId)))
      .limit(1);
    if (!shift) throw new NotFoundException('Shift not found');
    return shift;
  }

  async getCurrent(tenantId: string) {
    const [shift] = await this.db
      .select()
      .from(schema.shifts)
      .where(and(eq(schema.shifts.tenantId, tenantId), eq(schema.shifts.status, 'open')))
      .limit(1);
    return shift ?? null;
  }

  async open(tenantId: string, cashierId: string, dto: OpenShiftDto) {
    const existing = await this.getCurrent(tenantId);
    if (existing) throw new ConflictException('A shift is already open');

    const [shift] = await this.db
      .insert(schema.shifts)
      .values({
        tenantId,
        cashierId,
        openingCash: String(dto.openingCash),
        status: 'open',
        note: dto.note,
      })
      .returning();
    return shift;
  }

  async close(tenantId: string, dto: CloseShiftDto) {
    const shift = await this.getCurrent(tenantId);
    if (!shift) throw new BadRequestException('No open shift found');

    // Calculate total sales from completed orders during this shift period
    const now = new Date();
    const salesRows = await this.db
      .select({ total: schema.orders.totalAmount })
      .from(schema.orders)
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          eq(schema.orders.status, 'completed'),
          gte(schema.orders.completedAt, shift.openedAt),
          lte(schema.orders.completedAt, now),
        ),
      );

    const totalSales = salesRows
      .reduce((sum, r) => sum + parseFloat(r.total ?? '0'), 0)
      .toFixed(2);

    const expectedCash = parseFloat(shift.openingCash) + parseFloat(totalSales);
    const cashDifference = dto.closingCash - expectedCash;

    const [updated] = await this.db
      .update(schema.shifts)
      .set({
        status: 'closed',
        closingCash: String(dto.closingCash),
        expectedCash: String(expectedCash.toFixed(2)),
        cashDifference: String(cashDifference.toFixed(2)),
        totalSales,
        closedAt: new Date(),
        note: dto.note ?? shift.note,
      })
      .where(eq(schema.shifts.id, shift.id))
      .returning();
    return updated;
  }
}
