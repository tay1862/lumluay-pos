import { Injectable } from '@nestjs/common';
import { eq, and, desc, max } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';

/** Receipt number format: RC-YYYYMMDD-NNNN */
const PREFIX = 'RC';
const PAD = 4;

@Injectable()
export class ReceiptNumberService {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  /** Generate the next sequential receipt number for a tenant on a given date */
  async next(tenantId: string, date: Date = new Date()): Promise<string> {
    const datePart = date
      .toISOString()
      .slice(0, 10)
      .replace(/-/g, '');

    // Find max receipt_number for this tenant & date prefix
    const prefix = `${PREFIX}-${datePart}-`;

    const [row] = await this.db
      .select({ maxNum: max(schema.orders.receiptNumber) })
      .from(schema.orders)
      .where(
        and(
          eq(schema.orders.tenantId, tenantId),
          // Filter by date prefix using a SQL LIKE would be cleaner, but
          // since we control the format, we can parse the sequence from the max.
        ),
      );

    let seq = 1;
    const current = row?.maxNum;
    if (current && current.startsWith(prefix)) {
      const parts = current.split('-');
      seq = parseInt(parts[parts.length - 1] ?? '0', 10) + 1;
    }

    return `${prefix}${String(seq).padStart(PAD, '0')}`;
  }
}

/** Standalone (non-injectable) helper for simple sequential formatting */
export function formatReceiptNumber(
  seq: number,
  date: Date = new Date(),
): string {
  const datePart = date.toISOString().slice(0, 10).replace(/-/g, '');
  return `${PREFIX}-${datePart}-${String(seq).padStart(PAD, '0')}`;
}
