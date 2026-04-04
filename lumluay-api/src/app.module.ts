import { Module, MiddlewareConsumer, NestModule } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { TenantRlsInterceptor } from './common/interceptors/tenant-rls.interceptor';
import { ThrottlerModule } from '@nestjs/throttler';
import { ScheduleModule } from '@nestjs/schedule';
import { DatabaseModule } from './database/database.module';
import { RedisModule } from './config/redis.module';
import { AuthModule } from './modules/auth/auth.module';
import { TenantModule } from './modules/tenant/tenant.module';
import { UsersModule } from './modules/users/users.module';
import { CategoriesModule } from './modules/categories/categories.module';
import { ProductsModule } from './modules/products/products.module';
import { TablesModule } from './modules/tables/tables.module';
import { OrdersModule } from './modules/orders/orders.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { KitchenModule } from './modules/kitchen/kitchen.module';
import { StockModule } from './modules/stock/stock.module';
import { MembersModule } from './modules/members/members.module';
import { ShiftsModule } from './modules/shifts/shifts.module';
import { CouponsModule } from './modules/coupons/coupons.module';
import { QueueModule } from './modules/queue/queue.module';
import { ReportsModule } from './modules/reports/reports.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { SyncModule } from './modules/sync/sync.module';
import { SettingsModule } from './modules/settings/settings.module';
import { ImportExportModule } from './modules/import-export/import-export.module';
import { PublicModule } from './modules/public/public.module';
import { AdminModule } from './modules/admin/admin.module';
import { HealthModule } from './modules/health/health.module';
import { ModifierGroupsModule } from './modules/modifier-groups/modifier-groups.module';
import { DashboardModule } from './modules/dashboard/dashboard.module';
import { AuditLogsModule } from './modules/audit-logs/audit-logs.module';
import { BackupModule } from './modules/backup/backup.module';
import { TenantMiddleware } from './common/middleware/tenant.middleware';
import appConfig from './config/app.config';
import { validateEnv } from './config/env.validation';

@Module({
  imports: [
    // ─── Config ─────────────────────────────────────────────────
    ConfigModule.forRoot({
      isGlobal: true,
      load: [appConfig],
      envFilePath: ['.env'],
      validate: validateEnv,
    }),

    // ─── Throttler (Rate Limiting) ───────────────────────────────
    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60000,
        limit: 100,
      },
    ]),

    // ─── Scheduler ───────────────────────────────────────────────
    ScheduleModule.forRoot(),

    // ─── Infrastructure ──────────────────────────────────────────
    DatabaseModule,
    RedisModule,

    // ─── Feature Modules ─────────────────────────────────────────
    AuthModule,
    TenantModule,
    UsersModule,
    CategoriesModule,
    ProductsModule,
    TablesModule,
    OrdersModule,
    PaymentsModule,
    KitchenModule,
    StockModule,
    MembersModule,
    ShiftsModule,
    CouponsModule,
    QueueModule,
    ReportsModule,
    NotificationsModule,
    SyncModule,
    SettingsModule,
    ImportExportModule,
    PublicModule,
    AdminModule,
    HealthModule,
    ModifierGroupsModule,
    DashboardModule,
    AuditLogsModule,
    BackupModule,
  ],
  providers: [
    {
      provide: APP_INTERCEPTOR,
      useClass: TenantRlsInterceptor,
    },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(TenantMiddleware)
      .exclude('v1/auth/(.*)', 'v1/health', 'v1/public/(.*)', 'v1/admin/(.*)')
      .forRoutes('*');
  }
}
