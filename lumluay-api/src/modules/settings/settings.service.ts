import { Injectable, NotFoundException, Inject } from '@nestjs/common';
import { eq, and } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';
import {
  UpdateSettingsDto,
  CreateTaxRateDto,
  UpdateTaxRateDto,
  UpdateCurrenciesDto,
  UpdateExchangeRatesDto,
  UpdateReceiptSettingsDto,
  CreatePrinterDto,
  UpdatePrinterDto,
} from './dto/settings.dto';
import { randomUUID } from 'crypto';
import { REDIS_CLIENT } from '@/config/redis.module';
import Redis from 'ioredis';

type PrinterType = 'bluetooth' | 'usb' | 'wifi';

export interface PrinterConfig {
  id: string;
  name: string;
  type: PrinterType;
  ipAddress: string;
  port: number;
  isDefault: boolean;
  createdAt: string;
  updatedAt: string;
}

@Injectable()
export class SettingsService {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  private async ensureStoreSettings(tenantId: string) {
    const rows = await this.db
      .select()
      .from(schema.storeSettings)
      .where(eq(schema.storeSettings.tenantId, tenantId))
      .limit(1);

    if (rows.length > 0) {
      return rows[0];
    }

    const [created] = await this.db
      .insert(schema.storeSettings)
      .values({ tenantId })
      .returning();
    return created;
  }

  private normalizeExtra(extra: unknown): Record<string, any> {
    if (extra && typeof extra === 'object' && !Array.isArray(extra)) {
      return extra as Record<string, any>;
    }
    return {};
  }

  private async patchExtra(
    tenantId: string,
    patcher: (extra: Record<string, any>) => Record<string, any>,
  ) {
    const settings = await this.ensureStoreSettings(tenantId);
    const currentExtra = this.normalizeExtra(settings.extra);
    const nextExtra = patcher(currentExtra);

    const [updated] = await this.db
      .update(schema.storeSettings)
      .set({ extra: nextExtra, updatedAt: new Date() })
      .where(eq(schema.storeSettings.tenantId, tenantId))
      .returning();

    return updated;
  }

  async getSettings(tenantId: string) {
    const [rows, taxRates] = await Promise.all([
      this.db
        .select()
        .from(schema.storeSettings)
        .where(eq(schema.storeSettings.tenantId, tenantId))
        .limit(1),
      this.db
        .select()
        .from(schema.taxRates)
        .where(eq(schema.taxRates.tenantId, tenantId)),
    ]);
    return { settings: rows[0] ?? null, taxRates };
  }

  async updateSettings(tenantId: string, dto: UpdateSettingsDto) {
    await this.ensureStoreSettings(tenantId);

    const [updated] = await this.db
      .update(schema.storeSettings)
      .set({
        ...dto,
        serviceChargePercent: dto.serviceChargePercent != null ? String(dto.serviceChargePercent) : undefined,
        maxDiscountPercent: dto.maxDiscountPercent != null ? String(dto.maxDiscountPercent) : undefined,
        updatedAt: new Date(),
      })
      .where(eq(schema.storeSettings.tenantId, tenantId))
      .returning();
    return updated;
  }

  // ── Tax Rates ──────────────────────────────────────────────────────────────

  async getTaxRates(tenantId: string) {
    return this.db
      .select()
      .from(schema.taxRates)
      .where(eq(schema.taxRates.tenantId, tenantId));
  }

  async createTaxRate(tenantId: string, dto: CreateTaxRateDto) {
    // If marking as default, unset current default first
    if (dto.isDefault) {
      await this.db
        .update(schema.taxRates)
        .set({ isDefault: false })
        .where(and(eq(schema.taxRates.tenantId, tenantId), eq(schema.taxRates.isDefault, true)));
    }
    const [created] = await this.db
      .insert(schema.taxRates)
      .values({ tenantId, name: dto.name, rate: String(dto.rate), isDefault: dto.isDefault })
      .returning();
    return created;
  }

  async updateTaxRate(tenantId: string, id: string, dto: UpdateTaxRateDto) {
    if (dto.isDefault) {
      await this.db
        .update(schema.taxRates)
        .set({ isDefault: false })
        .where(and(eq(schema.taxRates.tenantId, tenantId), eq(schema.taxRates.isDefault, true)));
    }
    const [updated] = await this.db
      .update(schema.taxRates)
      .set({
        ...dto,
        rate: dto.rate != null ? String(dto.rate) : undefined,
      })
      .where(and(eq(schema.taxRates.id, id), eq(schema.taxRates.tenantId, tenantId)))
      .returning();
    if (!updated) throw new NotFoundException('Tax rate not found');
    return updated;
  }

  async deleteTaxRate(tenantId: string, id: string) {
    const [deleted] = await this.db
      .delete(schema.taxRates)
      .where(and(eq(schema.taxRates.id, id), eq(schema.taxRates.tenantId, tenantId)))
      .returning();
    if (!deleted) throw new NotFoundException('Tax rate not found');
  }

  // ── Currencies & Exchange Rates ───────────────────────────────────────────

  async getCurrencies(tenantId: string) {
    const settings = await this.ensureStoreSettings(tenantId);
    const extra = this.normalizeExtra(settings.extra);
    const currencies = extra.currencies ?? {};
    const exchangeRates = extra.exchangeRates ?? {};

    return {
      defaultCurrency: currencies.defaultCurrency ?? 'LAK',
      enabledCurrencies: currencies.enabledCurrencies ?? ['LAK'],
      decimals: currencies.decimals ?? { THB: 2, LAK: 0, USD: 2 },
      exchangeRates,
    };
  }

  async updateCurrencies(tenantId: string, dto: UpdateCurrenciesDto) {
    const updated = await this.patchExtra(tenantId, (extra) => {
      const current = extra.currencies ?? {};
      return {
        ...extra,
        currencies: {
          ...current,
          ...(dto.defaultCurrency != null
            ? { defaultCurrency: dto.defaultCurrency.toUpperCase() }
            : {}),
          ...(dto.enabledCurrencies != null
            ? {
                enabledCurrencies: dto.enabledCurrencies.map((c) =>
                  c.toUpperCase(),
                ),
              }
            : {}),
          ...(dto.decimals != null ? { decimals: dto.decimals } : {}),
        },
      };
    });

    const extra = this.normalizeExtra(updated.extra);
    return {
      defaultCurrency: extra.currencies?.defaultCurrency ?? 'LAK',
      enabledCurrencies: extra.currencies?.enabledCurrencies ?? ['LAK'],
      decimals: extra.currencies?.decimals ?? { THB: 2, LAK: 0, USD: 2 },
    };
  }

  async updateExchangeRates(tenantId: string, dto: UpdateExchangeRatesDto) {
    const updated = await this.patchExtra(tenantId, (extra) => ({
      ...extra,
      exchangeRates: dto.rates,
    }));
    await this.redis.del(`exchange:rates:${tenantId}`);
    const extra = this.normalizeExtra(updated.extra);
    return { rates: extra.exchangeRates ?? {} };
  }

  // ── Receipt Settings ───────────────────────────────────────────────────────

  async getReceiptSettings(tenantId: string) {
    const settings = await this.ensureStoreSettings(tenantId);
    const extra = this.normalizeExtra(settings.extra);
    return {
      header: settings.receiptHeader ?? '',
      footer: settings.receiptFooter ?? '',
      prefix: extra.receiptPrefix ?? 'RC',
      width: settings.receiptWidth ?? 80,
      showLogo: settings.receiptShowLogo,
    };
  }

  async updateReceiptSettings(tenantId: string, dto: UpdateReceiptSettingsDto) {
    const settings = await this.ensureStoreSettings(tenantId);
    const extra = this.normalizeExtra(settings.extra);

    const [updated] = await this.db
      .update(schema.storeSettings)
      .set({
        receiptHeader: dto.header ?? undefined,
        receiptFooter: dto.footer ?? undefined,
        receiptWidth: dto.width ?? undefined,
        receiptShowLogo: dto.showLogo ?? undefined,
        extra:
          dto.prefix != null
            ? { ...extra, receiptPrefix: dto.prefix }
            : settings.extra,
        updatedAt: new Date(),
      })
      .where(eq(schema.storeSettings.tenantId, tenantId))
      .returning();

    const nextExtra = this.normalizeExtra(updated.extra);
    return {
      header: updated.receiptHeader ?? '',
      footer: updated.receiptFooter ?? '',
      prefix: nextExtra.receiptPrefix ?? 'RC',
      width: updated.receiptWidth ?? 80,
      showLogo: updated.receiptShowLogo,
    };
  }

  // ── Printer Config ─────────────────────────────────────────────────────────

  async getPrinters(tenantId: string) {
    const settings = await this.ensureStoreSettings(tenantId);
    const extra = this.normalizeExtra(settings.extra);
    return (extra.printers ?? []) as PrinterConfig[];
  }

  async createPrinter(tenantId: string, dto: CreatePrinterDto) {
    const now = new Date().toISOString();
    let createdPrinter: PrinterConfig | null = null;

    await this.patchExtra(tenantId, (extra) => {
      const list: PrinterConfig[] = (extra.printers ?? []) as PrinterConfig[];
      const nextList = list.map((p) =>
        dto.isDefault ? { ...p, isDefault: false } : p,
      );

      createdPrinter = {
        id: randomUUID(),
        name: dto.name,
        type: dto.type,
        ipAddress: dto.ipAddress ?? '',
        port: dto.port ?? 9100,
        isDefault: dto.isDefault ?? nextList.length === 0,
        createdAt: now,
        updatedAt: now,
      };

      nextList.push(createdPrinter);
      return { ...extra, printers: nextList };
    });

    return createdPrinter;
  }

  async updatePrinter(tenantId: string, id: string, dto: UpdatePrinterDto) {
    let updatedPrinter: PrinterConfig | null = null;

    await this.patchExtra(tenantId, (extra) => {
      const list: PrinterConfig[] = (extra.printers ?? []) as PrinterConfig[];
      if (!list.some((p) => p.id === id)) {
        throw new NotFoundException('Printer not found');
      }

      let nextList = list.map((p) => ({ ...p }));
      if (dto.isDefault) {
        nextList = nextList.map((p) => ({ ...p, isDefault: false }));
      }

      nextList = nextList.map((p) => {
        if (p.id !== id) return p;
        updatedPrinter = {
          ...p,
          ...(dto.name != null ? { name: dto.name } : {}),
          ...(dto.type != null ? { type: dto.type } : {}),
          ...(dto.ipAddress != null ? { ipAddress: dto.ipAddress } : {}),
          ...(dto.port != null ? { port: dto.port } : {}),
          ...(dto.isDefault != null ? { isDefault: dto.isDefault } : {}),
          updatedAt: new Date().toISOString(),
        };
        return updatedPrinter;
      });

      return { ...extra, printers: nextList };
    });

    return updatedPrinter;
  }

  async deletePrinter(tenantId: string, id: string) {
    await this.patchExtra(tenantId, (extra) => {
      const list: PrinterConfig[] = (extra.printers ?? []) as PrinterConfig[];
      const existing = list.find((p) => p.id === id);
      if (!existing) {
        throw new NotFoundException('Printer not found');
      }

      const filtered = list.filter((p) => p.id !== id);
      if (existing.isDefault && filtered.length > 0) {
        filtered[0] = { ...filtered[0], isDefault: true };
      }

      return { ...extra, printers: filtered };
    });
  }

  async seedSampleData(tenantId: string, clearExisting = false) {
    if (clearExisting) {
      await this.db
        .delete(schema.products)
        .where(eq(schema.products.tenantId, tenantId));
      await this.db
        .delete(schema.categories)
        .where(eq(schema.categories.tenantId, tenantId));
    }

    const existingCategories = await this.db
      .select()
      .from(schema.categories)
      .where(eq(schema.categories.tenantId, tenantId));

    const existingProducts = await this.db
      .select()
      .from(schema.products)
      .where(eq(schema.products.tenantId, tenantId));

    if (!clearExisting && (existingCategories.length > 0 || existingProducts.length > 0)) {
      return {
        createdCategories: 0,
        createdProducts: 0,
        skipped: true,
        reason: 'Existing products or categories found',
      };
    }

    const sampleCategories = [
      { name: 'ອາຫານຫຼັກ', color: '#EF4444' },
      { name: 'ຂອງກິນຫຼິ້ນ', color: '#F59E0B' },
      { name: 'ເຄື່ອງດື່ມ', color: '#3B82F6' },
      { name: 'ຂອງຫວານ', color: '#A855F7' },
      { name: 'ເມນູແນະນຳ', color: '#10B981' },
    ];

    const insertedCategories = await this.db
      .insert(schema.categories)
      .values(
        sampleCategories.map((c, index) => ({
          tenantId,
          name: c.name,
          color: c.color,
          sortOrder: index,
        })),
      )
      .returning({ id: schema.categories.id, name: schema.categories.name });

    const cat = (name: string) =>
      insertedCategories.find((c) => c.name === name)?.id ?? null;

    const sampleProducts = [
      ['ເຂົ້າກະເພົາໝູສັບ', 65, 'ອາຫານຫຼັກ'],
      ['ເຂົ້າຜັດທະເລ', 85, 'ອາຫານຫຼັກ'],
      ['ຜັດໄທກຸ້ງສົດ', 90, 'ອາຫານຫຼັກ'],
      ['ຕົ້ມຍຳກຸ້ງນ້ຳຂົ້ນ', 120, 'ອາຫານຫຼັກ'],
      ['ເຂົ້າມັນໄກ່', 60, 'ອາຫານຫຼັກ'],
      ['ປີກໄກ່ທອດນ້ຳປາ', 75, 'ຂອງກິນຫຼິ້ນ'],
      ['ຟຣັນຊ໌ຟຣາຍ', 55, 'ຂອງກິນຫຼິ້ນ'],
      ['ໝູສະເຕະ', 80, 'ຂອງກິນຫຼິ້ນ'],
      ['ຍຳວຸ້ນເສັ້ນ', 95, 'ຂອງກິນຫຼິ້ນ'],
      ['ນັກເກັດໄກ່', 69, 'ຂອງກິນຫຼິ້ນ'],
      ['ນ້ຳເປົ່າ', 15, 'ເຄື່ອງດື່ມ'],
      ['ໂຄ້ກ', 25, 'ເຄື່ອງດື່ມ'],
      ['ຊາເຢັນ', 35, 'ເຄື່ອງດື່ມ'],
      ['ກາເຟເຢັນ', 45, 'ເຄື່ອງດື່ມ'],
      ['ນ້ຳສົ້ມຄັ້ນສົດ', 50, 'ເຄື່ອງດື່ມ'],
      ['ໄອສະກຣີມກະທິ', 49, 'ຂອງຫວານ'],
      ['ບົວລອຍໄຂ່ຫວານ', 55, 'ຂອງຫວານ'],
      ['ເຉົ້າກ້ວຍນົມສົດ', 40, 'ຂອງຫວານ'],
      ['ເຂົ້າໜຽວໝາກມ່ວງ', 89, 'ຂອງຫວານ'],
      ['ເຄັກໝາກພ້າວ', 75, 'ຂອງຫວານ'],
    ] as const;

    const insertedProducts = await this.db
      .insert(schema.products)
      .values(
        sampleProducts.map((p, index) => {
          const categoryId = cat(p[2]);
          return {
            tenantId,
            ...(categoryId != null ? { categoryId } : {}),
            name: p[0],
            basePrice: String(p[1]),
            productType: 'simple' as const,
            sortOrder: index,
            trackStock: false,
            allowModifiers: true,
            isActive: true,
          };
        }),
      )
      .returning({ id: schema.products.id });

    return {
      createdCategories: insertedCategories.length,
      createdProducts: insertedProducts.length,
      skipped: false,
    };
  }
}
