import { z } from 'zod';

// ─── Schema ───────────────────────────────────────────────────────────────────
const envSchema = z.object({
  // App
  NODE_ENV: z
    .enum(['development', 'staging', 'production'])
    .default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  API_PREFIX: z.string().default('v1'),
  LOG_LEVEL: z.string().optional(),

  // Database (required — no default)
  DATABASE_URL: z
    .string({ required_error: 'DATABASE_URL is required' })
    .min(1, 'DATABASE_URL must not be empty'),
  DATABASE_POOL_MIN: z.coerce.number().int().nonnegative().default(2),
  DATABASE_POOL_MAX: z.coerce.number().int().positive().default(10),

  // Redis
  REDIS_HOST: z.string().default('localhost'),
  REDIS_PORT: z.coerce.number().int().positive().default(6379),
  REDIS_PASSWORD: z.string().optional(),

  // JWT (required — no default)
  JWT_SECRET: z
    .string({ required_error: 'JWT_SECRET is required' })
    .min(1, 'JWT_SECRET must not be empty'),
  JWT_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_SECRET: z
    .string({ required_error: 'JWT_REFRESH_SECRET is required' })
    .min(1, 'JWT_REFRESH_SECRET must not be empty'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('30d'),

  // Security
  BCRYPT_ROUNDS: z.coerce.number().int().min(10).max(14).default(12),

  // Upload
  UPLOAD_DIR: z.string().default('./uploads'),
  MAX_FILE_SIZE_MB: z.coerce.number().int().positive().default(5),

  // Super Admin
  SUPER_ADMIN_USERNAME: z.string().min(3).optional(),
  SUPER_ADMIN_PASSWORD: z.string().optional(),

  // CORS
  CORS_ORIGINS: z
    .string()
    .default('http://localhost:3001,http://localhost:8080'),

  // Rate Limiting
  THROTTLE_TTL_SECONDS: z.coerce.number().int().positive().default(60),
  THROTTLE_LIMIT_DEFAULT: z.coerce.number().int().positive().default(100),
  THROTTLE_LIMIT_AUTH: z.coerce.number().int().positive().default(5),
});

export type Env = z.infer<typeof envSchema>;

// ─── Validator (used in main.ts + ConfigModule) ───────────────────────────────
export function validateEnv(config: Record<string, unknown>): Env {
  const result = envSchema.safeParse(config);

  if (!result.success) {
    const errors = result.error.errors
      .map((e) => `  • ${e.path.join('.')}: ${e.message}`)
      .join('\n');
    throw new Error(`\n[env] Environment validation failed:\n${errors}\n`);
  }

  const env = result.data;

  // ── Production-only stricter checks ────────────────────────────────────────
  if (env.NODE_ENV === 'production') {
    const failures: string[] = [];

    if (
      env.JWT_SECRET === 'CHANGE_ME_IN_PRODUCTION' ||
      env.JWT_SECRET === 'change-this-to-a-very-long-random-secret-key-in-production'
    ) {
      failures.push('  • JWT_SECRET: must be changed from the example/default value');
    }
    if (env.JWT_SECRET.length < 32) {
      failures.push('  • JWT_SECRET: must be at least 32 characters in production');
    }

    if (
      env.JWT_REFRESH_SECRET === 'CHANGE_ME_REFRESH' ||
      env.JWT_REFRESH_SECRET === 'change-this-to-another-very-long-random-secret'
    ) {
      failures.push(
        '  • JWT_REFRESH_SECRET: must be changed from the example/default value',
      );
    }
    if (env.JWT_REFRESH_SECRET.length < 32) {
      failures.push(
        '  • JWT_REFRESH_SECRET: must be at least 32 characters in production',
      );
    }

    if (
      env.SUPER_ADMIN_PASSWORD === 'change-in-production' ||
      env.SUPER_ADMIN_PASSWORD === 'changeme'
    ) {
      failures.push(
        '  • SUPER_ADMIN_PASSWORD: must be changed from the example/default value',
      );
    }

    if (failures.length > 0) {
      throw new Error(
        `\n[env] Production environment validation failed:\n${failures.join('\n')}\n`,
      );
    }
  }

  return env;
}
