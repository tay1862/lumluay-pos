export default () => {
  const nodeEnv = process.env.NODE_ENV ?? 'development';
  const isProd = nodeEnv === 'production';

  // Require JWT secrets in production
  const jwtSecret = process.env.JWT_SECRET;
  const jwtRefreshSecret = process.env.JWT_REFRESH_SECRET;
  if (isProd && (!jwtSecret || !jwtRefreshSecret)) {
    throw new Error('JWT_SECRET and JWT_REFRESH_SECRET must be set in production');
  }

  return {
    port: parseInt(process.env.PORT ?? '3000', 10),
    apiPrefix: process.env.API_PREFIX ?? 'v1',
    nodeEnv,
    bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS ?? '12', 10),

    database: {
      url: process.env.DATABASE_URL,
      poolMin: parseInt(process.env.DATABASE_POOL_MIN ?? '2', 10),
      poolMax: parseInt(process.env.DATABASE_POOL_MAX ?? '10', 10),
    },

    redis: {
      host: process.env.REDIS_HOST ?? 'localhost',
      port: parseInt(process.env.REDIS_PORT ?? '6379', 10),
      password: process.env.REDIS_PASSWORD ?? undefined,
    },

    jwt: {
      secret: jwtSecret ?? 'dev-only-secret-do-not-use-in-production',
      expiresIn: process.env.JWT_EXPIRES_IN ?? '15m',
      refreshSecret: jwtRefreshSecret ?? 'dev-only-refresh-do-not-use-in-production',
      refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN ?? '30d',
    },

    upload: {
      dir: process.env.UPLOAD_DIR ?? './uploads',
      maxFileSizeMb: parseInt(process.env.MAX_FILE_SIZE_MB ?? '5', 10),
    },

    throttle: {
      ttlSeconds: parseInt(process.env.THROTTLE_TTL_SECONDS ?? '60', 10),
      limitDefault: parseInt(process.env.THROTTLE_LIMIT_DEFAULT ?? '100', 10),
      limitAuth: parseInt(process.env.THROTTLE_LIMIT_AUTH ?? '5', 10),
    },
  };
};
