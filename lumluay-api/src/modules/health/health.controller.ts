import { Controller, Get, Inject } from '@nestjs/common';
import { sql } from 'drizzle-orm';
import { InjectDrizzle } from '@/database/database.module';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import type * as schema from '@/database/schema';
import { REDIS_CLIENT } from '@/config/redis.module';
import { Redis } from 'ioredis';

@Controller('health')
export class HealthController {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  @Get()
  async check() {
    let dbStatus = 'ok';
    try {
      await this.db.execute(sql`SELECT 1`);
    } catch {
      dbStatus = 'error';
    }

    let redisStatus = 'ok';
    try {
      const pong = await this.redis.ping();
      if (pong !== 'PONG') redisStatus = 'error';
    } catch {
      redisStatus = 'error';
    }

    const allOk = dbStatus === 'ok' && redisStatus === 'ok';

    return {
      status: allOk ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      services: {
        database: dbStatus,
        redis: redisStatus,
        api: 'ok',
      },
    };
  }
}
