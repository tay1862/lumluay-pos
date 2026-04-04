import {
  Injectable,
  Inject,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { eq, and, isNull, desc } from 'drizzle-orm';
import * as bcrypt from 'bcryptjs';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import { users } from '@/database/schema';
import { CreateUserDto, UpdateUserDto, SetPinDto } from './dto/user.dto';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class UsersService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
    private readonly configService: ConfigService,
  ) {}

  async findAll(tenantId: string) {
    return this.db.query.users.findMany({
      where: and(eq(users.tenantId, tenantId), isNull(users.deletedAt)),
      orderBy: [desc(users.createdAt)],
      columns: {
        passwordHash: false,
        pinCode: false,
      },
    });
  }

  async findOne(tenantId: string, id: string) {
    const user = await this.db.query.users.findFirst({
      where: and(
        eq(users.tenantId, tenantId),
        eq(users.id, id),
        isNull(users.deletedAt),
      ),
      columns: {
        passwordHash: false,
        pinCode: false,
      },
    });
    if (!user) throw new NotFoundException(`User ${id} not found`);
    return user;
  }

  async create(tenantId: string, dto: CreateUserDto) {
    // Check username uniqueness
    const existing = await this.db.query.users.findFirst({
      where: and(
        eq(users.tenantId, tenantId),
        eq(users.username, dto.username),
        isNull(users.deletedAt),
      ),
    });
    if (existing) {
      throw new ConflictException(`Username "${dto.username}" already taken`);
    }

    const bcryptRounds = this.configService.get<number>('bcryptRounds', 12);
    const passwordHash = await bcrypt.hash(dto.password, bcryptRounds);

    let pinCode: string | undefined;
    if (dto.pinCode) {
      pinCode = await bcrypt.hash(dto.pinCode, 10);
    }

    const [newUser] = await this.db
      .insert(users)
      .values({
        tenantId,
        username: dto.username,
        passwordHash,
        pinCode,
        displayName: dto.displayName,
        email: dto.email,
        phone: dto.phone,
        role: dto.role,
        autoLockMinutes: dto.autoLockMinutes,
      })
      .returning({
        id: users.id,
        tenantId: users.tenantId,
        username: users.username,
        displayName: users.displayName,
        email: users.email,
        phone: users.phone,
        role: users.role,
        isActive: users.isActive,
        createdAt: users.createdAt,
      });

    return newUser;
  }

  async update(tenantId: string, id: string, dto: UpdateUserDto) {
    await this.findOne(tenantId, id);

    const [updated] = await this.db
      .update(users)
      .set({ ...dto, updatedAt: new Date() })
      .where(and(eq(users.tenantId, tenantId), eq(users.id, id)))
      .returning({
        id: users.id,
        displayName: users.displayName,
        email: users.email,
        role: users.role,
        isActive: users.isActive,
        updatedAt: users.updatedAt,
      });

    return updated;
  }

  async remove(tenantId: string, id: string) {
    await this.findOne(tenantId, id);
    await this.db
      .update(users)
      .set({ deletedAt: new Date() })
      .where(and(eq(users.tenantId, tenantId), eq(users.id, id)));
  }

  async setPin(tenantId: string, id: string, dto: SetPinDto) {
    await this.findOne(tenantId, id);
    const pinCode = await bcrypt.hash(dto.pin, 10);
    await this.db
      .update(users)
      .set({ pinCode, updatedAt: new Date() })
      .where(and(eq(users.tenantId, tenantId), eq(users.id, id)));
  }

  async resetPassword(tenantId: string, id: string, newPassword: string) {
    await this.findOne(tenantId, id);
    const bcryptRounds = this.configService.get<number>('bcryptRounds', 12);
    const passwordHash = await bcrypt.hash(newPassword, bcryptRounds);
    await this.db
      .update(users)
      .set({ passwordHash, updatedAt: new Date() })
      .where(and(eq(users.tenantId, tenantId), eq(users.id, id)));
  }
}
