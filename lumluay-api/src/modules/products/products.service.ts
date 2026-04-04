import {
  Injectable, Inject, NotFoundException,
} from '@nestjs/common';
import { eq, and, isNull, asc, desc, ilike } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { promises as fs } from 'node:fs';
import { join, extname } from 'node:path';
import { randomUUID } from 'node:crypto';
import sharp from 'sharp';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import { products, productVariants, unitConversions } from '@/database/schema';
import {
  CreateProductDto,
  UpdateProductDto,
  CreateVariantDto,
  CreateUnitConversionDto,
  UploadProductImageDto,
} from './dto/product.dto';
import { REDIS_CLIENT } from '@/config/redis.module';
import Redis from 'ioredis';

@Injectable()
export class ProductsService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  private listCacheKey(tenantId: string) {
    return `cache:products:list:${tenantId}`;
  }

  private barcodeCacheKey(tenantId: string, barcode: string) {
    return `cache:products:barcode:${tenantId}:${barcode}`;
  }

  private async invalidateCache(tenantId: string) {
    // Delete the list cache key directly — avoids KEYS which blocks Redis.
    // Per-barcode entries expire naturally via their 5-minute TTL.
    await this.redis.del(this.listCacheKey(tenantId));
  }

  findAll(tenantId: string) {
    return this.getCachedProductList(tenantId);
  }

  private async getCachedProductList(tenantId: string) {
    const key = this.listCacheKey(tenantId);
    const cached = await this.redis.get(key);
    if (cached) {
      return JSON.parse(cached) as Awaited<ReturnType<typeof this.db.query.products.findMany>>;
    }

    const rows = await this.db.query.products.findMany({
      where: and(eq(products.tenantId, tenantId), isNull(products.deletedAt)),
      orderBy: [asc(products.sortOrder), asc(products.name)],
      with: {
        category: true,
        variants: { where: eq(productVariants.isActive, true) },
      },
    });

    await this.redis.set(key, JSON.stringify(rows), 'EX', 300);
    return rows;
  }

  async findOne(tenantId: string, id: string) {
    const product = await this.db.query.products.findFirst({
      where: and(
        eq(products.tenantId, tenantId),
        eq(products.id, id),
        isNull(products.deletedAt),
      ),
      with: {
        category: true,
        variants: { where: eq(productVariants.isActive, true) },
        modifierGroups: true,
      },
    });
    if (!product) throw new NotFoundException(`Product ${id} not found`);
    return product;
  }

  async create(tenantId: string, dto: CreateProductDto) {
    const [product] = await this.db
      .insert(products)
      .values({
        tenantId,
        ...dto,
        basePrice: String(dto.basePrice),
        cost: dto.cost !== undefined ? String(dto.cost) : undefined,
      })
      .returning();
    await this.invalidateCache(tenantId);
    return product;
  }

  async update(tenantId: string, id: string, dto: UpdateProductDto) {
    await this.findOne(tenantId, id);
    const updateData: Record<string, unknown> = { ...dto, updatedAt: new Date() };
    if (dto.basePrice !== undefined) updateData.basePrice = String(dto.basePrice);
    if (dto.cost !== undefined) updateData.cost = String(dto.cost);

    const [updated] = await this.db
      .update(products)
      .set(updateData)
      .where(and(eq(products.tenantId, tenantId), eq(products.id, id)))
      .returning();
    await this.invalidateCache(tenantId);
    return updated;
  }

  async remove(tenantId: string, id: string) {
    await this.findOne(tenantId, id);
    await this.db
      .update(products)
      .set({ deletedAt: new Date() })
      .where(and(eq(products.tenantId, tenantId), eq(products.id, id)));
    await this.invalidateCache(tenantId);
  }

  // ─── Variants ──────────────────────────────────────────────────────────────
  async addVariant(tenantId: string, productId: string, dto: CreateVariantDto) {
    await this.findOne(tenantId, productId);
    const [variant] = await this.db
      .insert(productVariants)
      .values({
        tenantId,
        productId,
        ...dto,
        price: String(dto.price),
        cost: dto.cost !== undefined ? String(dto.cost) : undefined,
      })
      .returning();
    await this.invalidateCache(tenantId);
    return variant;
  }

  async removeVariant(tenantId: string, productId: string, variantId: string) {
    await this.db
      .update(productVariants)
      .set({ isActive: false, updatedAt: new Date() })
      .where(
        and(
          eq(productVariants.tenantId, tenantId),
          eq(productVariants.productId, productId),
          eq(productVariants.id, variantId),
        ),
      );
      await this.invalidateCache(tenantId);
  }

  // ─── Unit Conversions ─────────────────────────────────────────────────────
  async getUnitConversions(tenantId: string, productId: string) {
    await this.findOne(tenantId, productId);
    return this.db.query.unitConversions.findMany({
      where: and(
        eq(unitConversions.tenantId, tenantId),
        eq(unitConversions.productId, productId),
      ),
      orderBy: [asc(unitConversions.fromUnit), asc(unitConversions.toUnit)],
    });
  }

  async addUnitConversion(
    tenantId: string,
    productId: string,
    dto: CreateUnitConversionDto,
  ) {
    await this.findOne(tenantId, productId);
    const [created] = await this.db
      .insert(unitConversions)
      .values({
        tenantId,
        productId,
        fromUnit: dto.fromUnit,
        toUnit: dto.toUnit,
        conversionRate: String(dto.conversionRate),
      })
      .returning();
    await this.invalidateCache(tenantId);
    return created;
  }

  async removeUnitConversion(tenantId: string, productId: string, conversionId: string) {
    await this.db
      .delete(unitConversions)
      .where(
        and(
          eq(unitConversions.tenantId, tenantId),
          eq(unitConversions.productId, productId),
          eq(unitConversions.id, conversionId),
        ),
      );
      await this.invalidateCache(tenantId);
  }

  // ─── Image Upload ─────────────────────────────────────────────────────────
  async uploadImage(dto: UploadProductImageDto) {
    const uploadDir = join(process.cwd(), 'uploads', 'products');
    const thumbDir = join(uploadDir, 'thumbs');
    await fs.mkdir(uploadDir, { recursive: true });
    await fs.mkdir(thumbDir, { recursive: true });

    const sourceExt = extname(dto.fileName).toLowerCase();
    const extension = sourceExt || this.mimeTypeToExtension(dto.mimeType) || '.bin';
    const targetName = `${Date.now()}-${randomUUID()}.webp`;
    const thumbName = `${Date.now()}-${randomUUID()}-thumb.webp`;
    const filePath = join(uploadDir, targetName);
    const thumbPath = join(thumbDir, thumbName);

    const buffer = Buffer.from(dto.dataBase64, 'base64');
    const optimized = await sharp(buffer)
      .rotate()
      .resize({ width: 1600, height: 1600, fit: 'inside', withoutEnlargement: true })
      .webp({ quality: 82, effort: 4 })
      .toBuffer();

    const thumbnail = await sharp(optimized)
      .resize({ width: 320, height: 320, fit: 'cover', position: 'centre' })
      .webp({ quality: 78, effort: 4 })
      .toBuffer();

    await fs.writeFile(filePath, optimized);
    await fs.writeFile(thumbPath, thumbnail);

    return {
      fileName: targetName,
      url: `/uploads/products/${targetName}`,
      thumbnailUrl: `/uploads/products/thumbs/${thumbName}`,
      size: optimized.length,
      originalSize: buffer.length,
      mimeType: 'image/webp',
      optimized: optimized.length < buffer.length,
      sourceExtension: extension,
    };
  }

  private mimeTypeToExtension(mimeType?: string): string | null {
    if (!mimeType) return null;
    const map: Record<string, string> = {
      'image/jpeg': '.jpg',
      'image/png': '.png',
      'image/webp': '.webp',
      'image/gif': '.gif',
    };
    return map[mimeType] ?? null;
  }

  // ─── Barcode Lookup ────────────────────────────────────────────────────────
  async findByBarcode(tenantId: string, barcode: string) {
    const key = this.barcodeCacheKey(tenantId, barcode);
    const cached = await this.redis.get(key);
    if (cached) {
      return JSON.parse(cached) as Awaited<ReturnType<typeof this.db.query.products.findFirst>>;
    }

    const product = await this.db.query.products.findFirst({
      where: and(
        eq(products.tenantId, tenantId),
        eq(products.barcode, barcode),
        isNull(products.deletedAt),
      ),
      with: {
        category: true,
        variants: { where: eq(productVariants.isActive, true) },
      },
    });

    if (product) {
      await this.redis.set(key, JSON.stringify(product), 'EX', 300);
    }
    return product;
  }
}
