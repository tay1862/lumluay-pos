import { Injectable, BadRequestException } from '@nestjs/common';
import { eq, and } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';

interface ProductRow {
  name: string;
  sku?: string;
  price?: string | number;
  basePrice?: string | number;
  costPrice?: string | number;
  categoryName?: string;
  description?: string;
  barcode?: string;
  unit?: string;
  type?: string;
  productType?: string;
}

@Injectable()
export class ImportExportService {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  // ─── Export ──────────────────────────────────────────────────────────────────

  async exportProducts(tenantId: string) {
    const products = await this.db
      .select({
        id: schema.products.id,
        name: schema.products.name,
        sku: schema.products.sku,
        barcode: schema.products.barcode,
        basePrice: schema.products.basePrice,
        unit: schema.products.unit,
        productType: schema.products.productType,
        description: schema.products.description,
        isActive: schema.products.isActive,
        categoryId: schema.products.categoryId,
      })
      .from(schema.products)
      .where(eq(schema.products.tenantId, tenantId))
      .orderBy(schema.products.name);

    // Build CSV in-memory
    const headers = ['id', 'name', 'sku', 'barcode', 'basePrice', 'unit', 'productType', 'description', 'isActive', 'categoryId'];
    const rows = products.map((p) =>
      headers.map((h) => {
        const val = (p as Record<string, unknown>)[h];
        const str = val == null ? '' : String(val);
        return str.includes(',') ? `"${str.replace(/"/g, '""')}"` : str;
      }).join(','),
    );

    return [headers.join(','), ...rows].join('\n');
  }

  async exportMembers(tenantId: string) {
    const members = await this.db
      .select()
      .from(schema.members)
      .where(eq(schema.members.tenantId, tenantId))
      .orderBy(schema.members.name);

    const headers = ['id', 'name', 'phone', 'email', 'points', 'tier', 'isActive', 'createdAt'];
    const rows = members.map((m) =>
      headers.map((h) => {
        const val = (m as Record<string, unknown>)[h];
        const str = val == null ? '' : String(val);
        return str.includes(',') ? `"${str.replace(/"/g, '""')}"` : str;
      }).join(','),
    );

    return [headers.join(','), ...rows].join('\n');
  }

  // ─── Import ──────────────────────────────────────────────────────────────────

  async importProducts(tenantId: string, csvContent: string) {
    const lines = csvContent.trim().split('\n');
    if (lines.length < 2) throw new BadRequestException('CSV has no data rows');

    const headers = lines[0].split(',').map((h) => h.trim().replace(/^"|"$/g, ''));
    const rows: ProductRow[] = lines.slice(1).map((line) => {
      const values = this.parseCsvLine(line);
      return headers.reduce(
        (obj, h, i) => ({ ...obj, [h]: values[i] ?? '' }),
        {} as ProductRow,
      );
    });

    const results = { imported: 0, skipped: 0, errors: [] as string[] };

    for (const row of rows) {
      try {
        if (!row.name || !row.price) {
          results.skipped++;
          results.errors.push(`Row skipped: missing name or price`);
          continue;
        }

        // Resolve or create category
        let categoryId: string | null = null;
        if (row.categoryName) {
          const [cat] = await this.db
            .select({ id: schema.categories.id })
            .from(schema.categories)
            .where(
              and(
                eq(schema.categories.tenantId, tenantId),
                eq(schema.categories.name, row.categoryName),
              ),
            );
          categoryId = cat?.id ?? null;
        }

        await this.db.insert(schema.products).values({
          tenantId,
          name: String(row.name),
          sku: row.sku || null,
          barcode: row.barcode || null,
          basePrice: String(row.price ?? row.basePrice ?? '0'),
          unit: row.unit || 'unit',
          productType: (row.type as 'simple' | 'variant' | 'combo') || 'simple',
          description: row.description || null,
          categoryId,
          isActive: true,
        });

        results.imported++;
      } catch (err: unknown) {
        results.skipped++;
        results.errors.push(
          `Row "${row.name}" error: ${err instanceof Error ? err.message : 'Unknown'}`,
        );
      }
    }

    return results;
  }

  private parseCsvLine(line: string): string[] {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') {
        if (inQuotes && line[i + 1] === '"') {
          current += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch === ',' && !inQuotes) {
        result.push(current.trim());
        current = '';
      } else {
        current += ch;
      }
    }
    result.push(current.trim());
    return result;
  }
}
