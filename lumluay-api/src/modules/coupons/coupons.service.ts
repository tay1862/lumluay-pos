import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  Inject,
} from '@nestjs/common';
import { eq, and, desc, sql, isNull } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import { CreateCouponDto, UpdateCouponDto, ValidateCouponDto } from './dto/coupon.dto';

@Injectable()
export class CouponsService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  async findAll(tenantId: string, activeOnly = false) {
    const where = activeOnly
      ? and(
          eq(schema.coupons.tenantId, tenantId),
          eq(schema.coupons.isActive, true),
          isNull(schema.coupons.deletedAt),
        )
      : and(
          eq(schema.coupons.tenantId, tenantId),
          isNull(schema.coupons.deletedAt),
        );

    return this.db
      .select()
      .from(schema.coupons)
      .where(where)
      .orderBy(desc(schema.coupons.createdAt));
  }

  async findOne(tenantId: string, id: string) {
    const [coupon] = await this.db
      .select()
      .from(schema.coupons)
      .where(
        and(
          eq(schema.coupons.tenantId, tenantId),
          eq(schema.coupons.id, id),
          isNull(schema.coupons.deletedAt),
        ),
      );

    if (!coupon) throw new NotFoundException(`Coupon ${id} not found`);
    return coupon;
  }

  async findByCode(tenantId: string, code: string) {
    const [coupon] = await this.db
      .select()
      .from(schema.coupons)
      .where(
        and(
          eq(schema.coupons.tenantId, tenantId),
          eq(schema.coupons.code, code.toUpperCase()),
          isNull(schema.coupons.deletedAt),
        ),
      );

    if (!coupon) throw new NotFoundException(`Coupon code "${code}" not found`);
    return coupon;
  }

  async create(tenantId: string, dto: CreateCouponDto) {
    const existing = await this.db
      .select({ id: schema.coupons.id })
      .from(schema.coupons)
      .where(
        and(
          eq(schema.coupons.tenantId, tenantId),
          eq(schema.coupons.code, dto.code.toUpperCase()),
        ),
      );

    if (existing.length > 0)
      throw new ConflictException(`Coupon code "${dto.code}" already exists`);

    const [coupon] = await this.db
      .insert(schema.coupons)
      .values({
        tenantId,
        code: dto.code.toUpperCase(),
        name: dto.name,
        description: dto.description,
        type: dto.type,
        value: String(dto.value),
        minOrderAmount: dto.minOrderAmount != null ? String(dto.minOrderAmount) : null,
        maxDiscountAmount: dto.maxDiscountAmount != null ? String(dto.maxDiscountAmount) : null,
        usageLimit: dto.usageLimit,
        perUserLimit: dto.perUserLimit,
        startsAt: dto.startsAt ? new Date(dto.startsAt) : null,
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
      })
      .returning();

    return coupon;
  }

  async update(tenantId: string, id: string, dto: UpdateCouponDto) {
    await this.findOne(tenantId, id);

    const [coupon] = await this.db
      .update(schema.coupons)
      .set({
        ...dto,
        value: dto.value != null ? String(dto.value) : undefined,
        minOrderAmount: dto.minOrderAmount != null ? String(dto.minOrderAmount) : undefined,
        maxDiscountAmount: dto.maxDiscountAmount != null ? String(dto.maxDiscountAmount) : undefined,
        startsAt: dto.startsAt ? new Date(dto.startsAt) : undefined,
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : undefined,
        updatedAt: new Date(),
      })
      .where(and(eq(schema.coupons.tenantId, tenantId), eq(schema.coupons.id, id)))
      .returning();

    return coupon;
  }

  async remove(tenantId: string, id: string) {
    await this.findOne(tenantId, id);
    await this.db
      .update(schema.coupons)
      .set({ deletedAt: new Date(), isActive: false })
      .where(and(eq(schema.coupons.tenantId, tenantId), eq(schema.coupons.id, id)));
    return { deleted: true };
  }

  async validate(tenantId: string, dto: ValidateCouponDto) {
    const coupon = await this.findByCode(tenantId, dto.code);

    if (!coupon.isActive)
      throw new BadRequestException('Coupon is inactive');

    // NOTE: Using server time for expiry checks. In a distributed deployment
    // consider adding a small clock-skew tolerance (e.g., ±30 s) if clients
    // and servers may be out of sync.
    const now = new Date();
    if (coupon.startsAt && new Date(coupon.startsAt) > now)
      throw new BadRequestException('Coupon is not yet valid');

    if (coupon.expiresAt && new Date(coupon.expiresAt) < now)
      throw new BadRequestException('Coupon has expired');

    if (coupon.usageLimit != null && coupon.usageCount >= coupon.usageLimit)
      throw new BadRequestException('Coupon usage limit reached');

    if (coupon.minOrderAmount != null && dto.orderAmount < Number(coupon.minOrderAmount))
      throw new BadRequestException(
        `Minimum order amount is ${coupon.minOrderAmount}`,
      );

    // Calculate discount
    let discountAmount = 0;
    if (coupon.type === 'percent') {
      discountAmount = (dto.orderAmount * Number(coupon.value)) / 100;
      if (coupon.maxDiscountAmount != null) {
        discountAmount = Math.min(discountAmount, Number(coupon.maxDiscountAmount));
      }
    } else if (coupon.type === 'fixed') {
      discountAmount = Math.min(Number(coupon.value), dto.orderAmount);
    }

    return {
      coupon,
      discountAmount: Math.round(discountAmount * 100) / 100,
    };
  }

  async incrementUsage(id: string) {
    await this.db
      .update(schema.coupons)
      .set({ usageCount: sql`${schema.coupons.usageCount} + 1` })
      .where(eq(schema.coupons.id, id));
  }
}
