import { Controller, Get } from '@nestjs/common';
import { sql } from 'drizzle-orm';
import { InjectDrizzle } from '@/database/database.module';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import type * as schema from '@/database/schema';

@Controller('health')
export class HealthController {
  constructor(
    @InjectDrizzle() private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  @Get()
  async check() {
    let dbStatus = 'ok';
    try {
      await this.db.execute(sql`SELECT 1`);
    } catch {
      dbStatus = 'error';
    }

    return {
      status: dbStatus === 'ok' ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      services: {
        database: dbStatus,
        api: 'ok',
      },
    };
  }
}
