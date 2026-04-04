import { NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import { AuditInterceptor } from './common/interceptors/audit.interceptor';
import { SanitizePipe } from './common/pipes/sanitize.pipe';
import fastifyHelmet from '@fastify/helmet';
import fastifyCompress from '@fastify/compress';
import { validateEnv } from './config/env.validation';

async function bootstrap() {
  // ─── Validate ALL env vars before anything else (0.1.4) ──────
  validateEnv(process.env as Record<string, unknown>);

  const nodeEnv = process.env.NODE_ENV ?? 'development';
  const logLevel = process.env.LOG_LEVEL ?? (nodeEnv === 'production' ? 'info' : 'debug');

  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({
      logger: {
        level: logLevel,
      },
    }),
  );

  const configService = app.get(ConfigService);
  const port = configService.get<number>('PORT', 3000);
  const prefix = configService.get<string>('API_PREFIX', 'v1');

  // ─── Security headers (18.3.1) ───────────────────────────────
  await app.register(fastifyHelmet, {
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'https:'],
        scriptSrc: ["'self'"],
      },
    },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true,
    },
  });

  // ─── Gzip compression (18.4.6) ───────────────────────────────
  await app.register(fastifyCompress, {
    global: true,
    threshold: 1024,
  });

  // Global prefix
  app.setGlobalPrefix(prefix);

  // CORS
  const corsOrigins = configService.get<string>('CORS_ORIGINS', '').split(',');
  app.enableCors({
    origin: corsOrigins,
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
    credentials: true,
  });

  // Global pipes — sanitize first, then validate
  app.useGlobalPipes(
    new SanitizePipe(),
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // Global filters
  app.useGlobalFilters(new HttpExceptionFilter());

  // Global interceptors
  app.useGlobalInterceptors(
    new TransformInterceptor(),
    new AuditInterceptor(),
  );

  await app.listen(port, '0.0.0.0');
  console.log(`LUMLUAY API running on port ${port} (/${prefix})`);
}

bootstrap();
