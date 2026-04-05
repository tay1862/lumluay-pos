import { Injectable, UnauthorizedException, Inject, NotFoundException, HttpException, HttpStatus } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { eq, and, isNull, sql } from 'drizzle-orm';
import * as bcrypt from 'bcryptjs';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import { users, userSessions, tenants } from '@/database/schema';
import { LoginDto, LoginPinDto, RefreshTokenDto } from './dto/auth.dto';
import { createHash, randomBytes } from 'crypto';

const MAX_FAILED_ATTEMPTS = 10;
const LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes

@Injectable()
export class AuthService {
  constructor(
    @Inject(DATABASE) private readonly db: PostgresJsDatabase<typeof schema>,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async login(dto: LoginDto, ipAddress?: string) {
    // Resolve tenant from slug (auth routes are excluded from TenantMiddleware)
    const tenant = await this.db.query.tenants.findFirst({
      where: and(eq(tenants.slug, dto.tenantSlug), eq(tenants.isActive, true)),
    });
    if (!tenant) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const user = await this.db.query.users.findFirst({
      where: and(
        eq(users.tenantId, tenant.id),
        eq(users.username, dto.username),
        isNull(users.deletedAt),
      ),
    });

    if (!user || !user.isActive) {
      throw new UnauthorizedException('Invalid credentials');
    }

    this.checkLockout(user);

    const isValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isValid) {
      await this.recordFailedAttempt(user.id);
      throw new UnauthorizedException('Invalid credentials');
    }

    await this.resetFailedAttempts(user.id);
    const tokens = await this.generateTokens(user, dto.deviceId, dto.deviceName, ipAddress);

    await this.db
      .update(users)
      .set({ lastLoginAt: new Date() })
      .where(eq(users.id, user.id));

    return {
      user: this.mapUserResponse(user),
      ...tokens,
    };
  }

  async loginWithPin(dto: LoginPinDto, ipAddress?: string) {
    // Resolve tenant from slug (same as password login)
    const tenant = await this.db.query.tenants.findFirst({
      where: and(eq(tenants.slug, dto.tenantSlug), eq(tenants.isActive, true)),
    });
    if (!tenant) throw new UnauthorizedException('Invalid credentials');

    const user = await this.db.query.users.findFirst({
      where: and(
        eq(users.tenantId, tenant.id),
        eq(users.id, dto.userId),
        isNull(users.deletedAt),
      ),
    });

    if (!user || !user.isActive || !user.pinCode) {
      throw new UnauthorizedException('PIN login not available');
    }

    this.checkLockout(user);

    const isValid = await bcrypt.compare(dto.pin, user.pinCode);
    if (!isValid) {
      await this.recordFailedAttempt(user.id);
      throw new UnauthorizedException('Invalid PIN');
    }

    await this.resetFailedAttempts(user.id);
    const tokens = await this.generateTokens(user, dto.deviceId, undefined, ipAddress);

    return {
      user: this.mapUserResponse(user),
      ...tokens,
    };
  }

  async refresh(dto: RefreshTokenDto) {
    const tokenHash = this.hashToken(dto.refreshToken);
    const session = await this.db.query.userSessions.findFirst({
      where: eq(userSessions.refreshTokenHash, tokenHash),
      with: { user: true },
    });

    // ── 18.3.5 Token rotation: if token not found but was previously issued,
    // it may be a reuse attack — revoke ALL sessions for that user. ──────────
    if (!session) {
      // Attempt to decode the token to find userId for revocation
      try {
        const decoded = this.jwtService.decode(dto.refreshToken) as { sub?: string } | null;
        if (decoded?.sub) {
          await this.logoutAll(decoded.sub);
        }
      } catch {
        // ignore decode errors
      }
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    if (session.expiresAt < new Date()) {
      // Clean up expired session
      await this.db.delete(userSessions).where(eq(userSessions.id, session.id));
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const user = session.user;
    if (!user.isActive) {
      throw new UnauthorizedException('Account disabled');
    }

    const tokens = await this.generateTokens(
      user,
      session.deviceId ?? undefined,
      session.deviceName ?? undefined,
    );

    // Revoke old session (rotation)
    await this.db
      .delete(userSessions)
      .where(eq(userSessions.id, session.id));

    return tokens;
  }

  async logout(sessionId: string) {
    await this.db
      .delete(userSessions)
      .where(eq(userSessions.id, sessionId));
  }

  async logoutAll(userId: string) {
    await this.db
      .delete(userSessions)
      .where(eq(userSessions.userId, userId));
  }

  async validateJwtPayload(payload: { sub: string; tenantId: string }) {
    const user = await this.db.query.users.findFirst({
      where: and(
        eq(users.id, payload.sub),
        eq(users.tenantId, payload.tenantId),
        isNull(users.deletedAt),
      ),
    });

    if (!user || !user.isActive) return null;
    return user;
  }

  private async generateTokens(
    user: typeof users.$inferSelect,
    deviceId?: string,
    deviceName?: string,
    ipAddress?: string,
  ) {
    const payload = {
      sub: user.id,
      tenantId: user.tenantId,
      role: user.role,
      username: user.username,
      displayName: user.displayName,
    };

    const accessToken = await this.jwtService.signAsync(payload, {
      expiresIn: '15m',
      secret: this.configService.get<string>('jwt.secret'),
    });

    const refreshToken = randomBytes(64).toString('hex');
    const refreshTokenHash = this.hashToken(refreshToken);
    const accessTokenHash = this.hashToken(accessToken);

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);

    await this.db.insert(userSessions).values({
      userId: user.id,
      tenantId: user.tenantId ?? (() => { throw new UnauthorizedException('User has no tenant'); })(),
      deviceId: deviceId,
      deviceName: deviceName,
      tokenHash: accessTokenHash,
      refreshTokenHash,
      ipAddress: ipAddress as unknown as string,
      expiresAt,
    });

    return { accessToken, refreshToken };
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private mapUserResponse(user: typeof users.$inferSelect) {
    return {
      id: user.id,
      tenantId: user.tenantId,
      username: user.username,
      displayName: user.displayName,
      email: user.email,
      role: user.role,
      avatarUrl: user.avatarUrl,
      locale: user.locale,
    };
  }

  // ─── Account Lockout ───────────────────────────────────────────────────────

  private checkLockout(user: typeof users.$inferSelect) {
    if (
      user.lockedUntil &&
      new Date(user.lockedUntil) > new Date()
    ) {
      const retryAfterMs =
        new Date(user.lockedUntil).getTime() - Date.now();
      const retryAfterSec = Math.ceil(retryAfterMs / 1000);
      throw new HttpException(
        {
          statusCode: HttpStatus.TOO_MANY_REQUESTS,
          message: `Account locked due to too many failed attempts. Try again in ${Math.ceil(retryAfterSec / 60)} minute(s).`,
          retryAfterSeconds: retryAfterSec,
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private async recordFailedAttempt(userId: string) {
    const [updated] = await this.db
      .update(users)
      .set({
        failedLoginAttempts: sql`${users.failedLoginAttempts} + 1`,
      } as any)
      .where(eq(users.id, userId))
      .returning({ attempts: users.failedLoginAttempts });

    if (updated && updated.attempts >= MAX_FAILED_ATTEMPTS) {
      await this.db
        .update(users)
        .set({ lockedUntil: new Date(Date.now() + LOCKOUT_DURATION_MS) })
        .where(eq(users.id, userId));
    }
  }

  private async resetFailedAttempts(userId: string) {
    await this.db
      .update(users)
      .set({ failedLoginAttempts: 0, lockedUntil: null })
      .where(eq(users.id, userId));
  }
}
