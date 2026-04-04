import { Injectable, NotFoundException } from '@nestjs/common';
import { eq, and, asc, isNull } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { InjectDrizzle } from '@/database/database.module';
import * as schema from '@/database/schema';
import {
  CreateModifierGroupDto,
  UpdateModifierGroupDto,
  CreateModifierOptionDto,
  UpdateModifierOptionDto,
} from './dto/modifier-group.dto';

@Injectable()
export class ModifierGroupsService {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  // ─── Groups ────────────────────────────────────────────────────────────────

  async findAll(tenantId: string) {
    const groups = await this.db.query.modifierGroups.findMany({
      where: eq(schema.modifierGroups.tenantId, tenantId),
      orderBy: [asc(schema.modifierGroups.sortOrder), asc(schema.modifierGroups.name)],
      with: {
        options: {
          where: eq(schema.modifierOptions.isActive, true),
          orderBy: [asc(schema.modifierOptions.sortOrder)],
        },
      },
    });
    return groups;
  }

  async findOne(tenantId: string, id: string) {
    const group = await this.db.query.modifierGroups.findFirst({
      where: and(
        eq(schema.modifierGroups.id, id),
        eq(schema.modifierGroups.tenantId, tenantId),
      ),
      with: {
        options: {
          orderBy: [asc(schema.modifierOptions.sortOrder)],
        },
      },
    });
    if (!group) throw new NotFoundException(`ModifierGroup ${id} not found`);
    return group;
  }

  async create(tenantId: string, dto: CreateModifierGroupDto) {
    const [group] = await this.db
      .insert(schema.modifierGroups)
      .values({
        tenantId,
        name: dto.name,
        nameEn: dto.nameEn,
        isRequired: dto.isRequired ?? false,
        minSelect: dto.minSelect ?? 0,
        maxSelect: dto.maxSelect ?? 1,
        sortOrder: dto.sortOrder ?? 0,
      })
      .returning();

    // Create options if provided
    if (dto.options && dto.options.length > 0) {
      await this.db.insert(schema.modifierOptions).values(
        dto.options.map((opt, idx) => ({
          groupId: group.id,
          tenantId,
          name: opt.name,
          nameEn: opt.nameEn,
          extraPrice: String(opt.extraPrice ?? 0),
          isDefault: opt.isDefault ?? false,
          sortOrder: opt.sortOrder ?? idx,
        })),
      );
    }

    return this.findOne(tenantId, group.id);
  }

  async update(tenantId: string, id: string, dto: UpdateModifierGroupDto) {
    await this.findOne(tenantId, id);
    const [updated] = await this.db
      .update(schema.modifierGroups)
      .set({
        ...dto,
        updatedAt: new Date(),
      })
      .where(
        and(
          eq(schema.modifierGroups.id, id),
          eq(schema.modifierGroups.tenantId, tenantId),
        ),
      )
      .returning();
    return updated;
  }

  async remove(tenantId: string, id: string) {
    await this.findOne(tenantId, id);
    // Soft-delete all options, then set group inactive
    await this.db
      .update(schema.modifierOptions)
      .set({ isActive: false })
      .where(eq(schema.modifierOptions.groupId, id));
    await this.db
      .update(schema.modifierGroups)
      .set({ isActive: false, updatedAt: new Date() })
      .where(
        and(
          eq(schema.modifierGroups.id, id),
          eq(schema.modifierGroups.tenantId, tenantId),
        ),
      );
  }

  // ─── Options ──────────────────────────────────────────────────────────────

  async addOption(tenantId: string, groupId: string, dto: CreateModifierOptionDto) {
    await this.findOne(tenantId, groupId);
    const [option] = await this.db
      .insert(schema.modifierOptions)
      .values({
        groupId,
        tenantId,
        name: dto.name,
        nameEn: dto.nameEn,
        extraPrice: String(dto.extraPrice ?? 0),
        isDefault: dto.isDefault ?? false,
        sortOrder: dto.sortOrder ?? 0,
      })
      .returning();
    return option;
  }

  async updateOption(
    tenantId: string,
    groupId: string,
    optionId: string,
    dto: UpdateModifierOptionDto,
  ) {
    await this.findOne(tenantId, groupId);
    const [updated] = await this.db
      .update(schema.modifierOptions)
      .set({
        ...dto,
        extraPrice: dto.extraPrice !== undefined ? String(dto.extraPrice) : undefined,
      })
      .where(
        and(
          eq(schema.modifierOptions.id, optionId),
          eq(schema.modifierOptions.groupId, groupId),
          eq(schema.modifierOptions.tenantId, tenantId),
        ),
      )
      .returning();
    if (!updated) throw new NotFoundException(`Option ${optionId} not found`);
    return updated;
  }

  async removeOption(tenantId: string, groupId: string, optionId: string) {
    await this.findOne(tenantId, groupId);
    await this.db
      .update(schema.modifierOptions)
      .set({ isActive: false })
      .where(
        and(
          eq(schema.modifierOptions.id, optionId),
          eq(schema.modifierOptions.groupId, groupId),
          eq(schema.modifierOptions.tenantId, tenantId),
        ),
      );
  }

  // ─── Product linking ──────────────────────────────────────────────────────

  async getProductModifiers(tenantId: string, productId: string) {
    const links = await this.db.query.productModifierGroups.findMany({
      where: eq(schema.productModifierGroups.productId, productId),
      orderBy: [asc(schema.productModifierGroups.sortOrder)],
      with: {
        group: {
          with: {
            options: {
              where: eq(schema.modifierOptions.isActive, true),
              orderBy: [asc(schema.modifierOptions.sortOrder)],
            },
          },
        },
      },
    });

    return links
      .filter((l) => l.group.tenantId === tenantId && l.group.isActive)
      .map((l) => l.group);
  }

  async linkGroupToProduct(
    tenantId: string,
    productId: string,
    groupId: string,
  ) {
    await this.findOne(tenantId, groupId);
    // Upsert to avoid duplicate links
    await this.db
      .insert(schema.productModifierGroups)
      .values({ productId, groupId, sortOrder: 0 })
      .onConflictDoNothing();
    return { linked: true };
  }

  async unlinkGroupFromProduct(
    tenantId: string,
    productId: string,
    groupId: string,
  ) {
    await this.db
      .delete(schema.productModifierGroups)
      .where(
        and(
          eq(schema.productModifierGroups.productId, productId),
          eq(schema.productModifierGroups.groupId, groupId),
        ),
      );
    return { unlinked: true };
  }
}
