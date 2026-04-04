import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { eq, and, ilike, or, desc } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';
import { CreateMemberDto, UpdateMemberDto } from './dto/member.dto';

@Injectable()
export class MembersService {
  constructor(@InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>) {}

  async findAll(tenantId: string, search?: string) {
    const where = search
      ? and(
          eq(schema.members.tenantId, tenantId),
          or(
            ilike(schema.members.name, `%${search}%`),
            ilike(schema.members.phone, `%${search}%`),
          ),
        )
      : eq(schema.members.tenantId, tenantId);

    return this.db
      .select()
      .from(schema.members)
      .where(where)
      .orderBy(desc(schema.members.createdAt));
  }

  async findOne(tenantId: string, id: string) {
    const [member] = await this.db
      .select()
      .from(schema.members)
      .where(and(eq(schema.members.id, id), eq(schema.members.tenantId, tenantId)))
      .limit(1);
    if (!member) throw new NotFoundException('Member not found');
    return member;
  }

  async findByPhone(tenantId: string, phone: string) {
    const [member] = await this.db
      .select()
      .from(schema.members)
      .where(and(eq(schema.members.phone, phone), eq(schema.members.tenantId, tenantId)))
      .limit(1);
    return member ?? null;
  }

  async create(tenantId: string, dto: CreateMemberDto) {
    if (dto.phone) {
      const existing = await this.findByPhone(tenantId, dto.phone);
      if (existing) throw new ConflictException('Phone number already registered');
    }
    const [member] = await this.db
      .insert(schema.members)
      .values({ tenantId, ...dto })
      .returning();
    return member;
  }

  async update(tenantId: string, id: string, dto: UpdateMemberDto) {
    if (dto.phone) {
      const existing = await this.findByPhone(tenantId, dto.phone);
      if (existing && existing.id !== id) {
        throw new ConflictException('Phone number already registered');
      }
    }
    const [updated] = await this.db
      .update(schema.members)
      .set({ ...dto, updatedAt: new Date() })
      .where(and(eq(schema.members.id, id), eq(schema.members.tenantId, tenantId)))
      .returning();
    if (!updated) throw new NotFoundException('Member not found');
    return updated;
  }

  async remove(tenantId: string, id: string) {
    const [deleted] = await this.db
      .delete(schema.members)
      .where(and(eq(schema.members.id, id), eq(schema.members.tenantId, tenantId)))
      .returning();
    if (!deleted) throw new NotFoundException('Member not found');
  }

  async getOrderHistory(tenantId: string, id: string) {
    await this.findOne(tenantId, id);
    return this.db
      .select()
      .from(schema.orders)
      .where(and(eq(schema.orders.tenantId, tenantId), eq(schema.orders.customerId, id)))
      .orderBy(desc(schema.orders.createdAt));
  }
}
