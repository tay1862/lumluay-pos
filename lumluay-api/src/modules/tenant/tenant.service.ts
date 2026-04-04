import {
  Injectable,
  Inject,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { eq, isNull } from 'drizzle-orm';
import * as bcrypt from 'bcryptjs';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import { tenants, users, storeSettings } from '@/database/schema';
import { CreateTenantDto, UpdateTenantDto } from './dto/tenant.dto';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class TenantService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
    private readonly configService: ConfigService,
  ) {}

  async findBySlug(slug: string) {
    const tenant = await this.db.query.tenants.findFirst({
      where: eq(tenants.slug, slug),
    });
    if (!tenant) throw new NotFoundException(`Tenant "${slug}" not found`);
    return tenant;
  }

  async findById(id: string) {
    const tenant = await this.db.query.tenants.findFirst({
      where: eq(tenants.id, id),
    });
    if (!tenant) throw new NotFoundException(`Tenant not found`);
    return tenant;
  }

  async create(dto: CreateTenantDto) {
    const existing = await this.db.query.tenants.findFirst({
      where: eq(tenants.slug, dto.slug),
    });
    if (existing) {
      throw new ConflictException(`Slug "${dto.slug}" already taken`);
    }

    const bcryptRounds = this.configService.get<number>('bcryptRounds', 12);

    // Create tenant + owner user + default store settings in a single flow
    const [tenant] = await this.db
      .insert(tenants)
      .values({
        name: dto.name,
        slug: dto.slug,
        ownerName: dto.ownerName,
        email: dto.email,
        phone: dto.phone,
        address: dto.address,
        taxId: dto.taxId,
      })
      .returning();

    const passwordHash = await bcrypt.hash(dto.ownerPassword, bcryptRounds);

    const [owner] = await this.db
      .insert(users)
      .values({
        tenantId: tenant.id,
        username: dto.ownerUsername,
        passwordHash,
        displayName: dto.ownerName ?? dto.ownerUsername,
        role: 'owner',
      })
      .returning({
        id: users.id,
        username: users.username,
        role: users.role,
      });

    await this.db.insert(storeSettings).values({ tenantId: tenant.id });

    return { tenant, owner };
  }

  async update(id: string, dto: UpdateTenantDto) {
    await this.findById(id);
    const [updated] = await this.db
      .update(tenants)
      .set({ ...dto, updatedAt: new Date() })
      .where(eq(tenants.id, id))
      .returning();
    return updated;
  }

  async getSettings(tenantId: string) {
    const settings = await this.db.query.storeSettings.findFirst({
      where: eq(storeSettings.tenantId, tenantId),
    });
    if (!settings) throw new NotFoundException('Store settings not found');
    return settings;
  }

  async getTenantProfile(tenantId: string) {
    const [tenant, settings, taxRates] = await Promise.all([
      this.findById(tenantId),
      this.db.query.storeSettings.findFirst({
        where: eq(storeSettings.tenantId, tenantId),
      }),
      this.db.query.taxRates.findMany({
        where: eq(schema.taxRates.tenantId, tenantId),
      }),
    ]);

    return {
      tenant,
      settings: settings ?? null,
      taxRates,
    };
  }
}
