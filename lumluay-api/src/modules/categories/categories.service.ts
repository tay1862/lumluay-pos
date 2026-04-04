import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { eq, and, asc, sql } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import { categories } from '@/database/schema';
import { CreateCategoryDto, UpdateCategoryDto, ReorderItemDto } from './dto/category.dto';
import { REDIS_CLIENT } from '@/config/redis.module';
import Redis from 'ioredis';

@Injectable()
export class CategoriesService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  private listCacheKey(tenantId: string) {
    return `cache:categories:list:${tenantId}`;
  }

  private async invalidateCache(tenantId: string) {
    await this.redis.del(this.listCacheKey(tenantId));
  }

  findAll(tenantId: string) {
    return this.getCachedCategoryList(tenantId);
  }

  private async getCachedCategoryList(tenantId: string) {
    const key = this.listCacheKey(tenantId);
    const cached = await this.redis.get(key);
    if (cached) {
      return JSON.parse(cached) as Awaited<ReturnType<typeof this.db.query.categories.findMany>>;
    }

    const rows = await this.db.query.categories.findMany({
      where: and(eq(categories.tenantId, tenantId), eq(categories.isActive, true)),
      orderBy: [asc(categories.sortOrder), asc(categories.name)],
      with: {
        children: {
          where: eq(categories.isActive, true),
          orderBy: [asc(categories.sortOrder)],
        },
      },
    });

    await this.redis.set(key, JSON.stringify(rows), 'EX', 300);
    return rows;
  }

  async findOne(tenantId: string, id: string) {
    const cat = await this.db.query.categories.findFirst({
      where: and(eq(categories.tenantId, tenantId), eq(categories.id, id)),
    });
    if (!cat) throw new NotFoundException(`Category ${id} not found`);
    return cat;
  }

  async create(tenantId: string, dto: CreateCategoryDto) {
    const slug = dto.name.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
    const [cat] = await this.db
      .insert(categories)
      .values({ tenantId, ...dto, slug })
      .returning();
    await this.invalidateCache(tenantId);
    return cat;
  }

  async update(tenantId: string, id: string, dto: UpdateCategoryDto) {
    await this.findOne(tenantId, id);
    const [updated] = await this.db
      .update(categories)
      .set({ ...dto, updatedAt: new Date() })
      .where(and(eq(categories.tenantId, tenantId), eq(categories.id, id)))
      .returning();
    await this.invalidateCache(tenantId);
    return updated;
  }

  async remove(tenantId: string, id: string) {
    await this.findOne(tenantId, id);
    await this.db
      .update(categories)
      .set({ isActive: false, updatedAt: new Date() })
      .where(and(eq(categories.tenantId, tenantId), eq(categories.id, id)));
    await this.invalidateCache(tenantId);
  }

  async reorder(tenantId: string, items: ReorderItemDto[]): Promise<void> {
    await Promise.all(
      items.map((item) =>
        this.db
          .update(categories)
          .set({ sortOrder: item.sortOrder, updatedAt: new Date() })
          .where(
            and(
              eq(categories.tenantId, tenantId),
              eq(categories.id, item.id),
            ),
          ),
      ),
    );
    await this.invalidateCache(tenantId);
  }
}
