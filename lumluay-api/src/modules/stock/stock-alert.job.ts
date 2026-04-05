import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { and, eq, lte, gt } from 'drizzle-orm';
import { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import { Inject } from '@nestjs/common';
import { DATABASE } from '@/database/database.module';
import * as schema from '@/database/schema';
import { stockLevels } from '@/database/schema';
import { NotificationsService } from '@/modules/notifications/notifications.service';

/**
 * StockAlertJob — 11.1.6
 *
 * Runs after every sale completion (via deductStock) AND on a background
 * cron schedule as a safety net.  Finds all stock levels that are at or below
 * their low_stock_threshold and creates a notification for each tenant.
 *
 * De-duplication: skips products that already have an unread low_stock
 * notification created within the last 6 hours to avoid notification spam.
 */
@Injectable()
export class StockAlertJob {
  private readonly logger = new Logger(StockAlertJob.name);

  constructor(
    @Inject(DATABASE)
    private readonly db: PostgresJsDatabase<typeof schema>,
    private readonly notificationsService: NotificationsService,
  ) {}

  // Run every 15 minutes as background sweep
  @Cron(CronExpression.EVERY_30_MINUTES)
  async checkLowStock() {
    this.logger.debug('Running low-stock check sweep…');

    // Find all stock levels where quantity <= low_stock_threshold (and threshold > 0)
    const lowItems = await this.db.query.stockLevels.findMany({
      where: and(
        gt(stockLevels.lowStockThreshold, '0'),
        lte(stockLevels.quantity, stockLevels.lowStockThreshold),
      ),
      with: { product: true },
    });

    for (const item of lowItems) {
      if (!item.product) continue;

      // De-duplicate: check for existing recent notification
      const sixHoursAgo = new Date(Date.now() - 6 * 60 * 60 * 1000);
      const existing = await this.db.query.notifications.findFirst({
        where: and(
          eq(schema.notifications.tenantId, item.tenantId),
          eq(schema.notifications.type, 'low_stock'),
        ),
      });

      if (existing && existing.createdAt > sixHoursAgo) {
        // Check if it's for this specific product
        const data = existing.data as Record<string, unknown> | null;
        if (data?.productId === item.productId) continue;
      }

      await this.notificationsService.create(item.tenantId, {
        type: 'low_stock',
        title: 'ສິນຄ້າໃກ້ໝົດ',
        body: `${item.product.name} ເຫຼືອ ${Number(item.quantity)} ${item.product.unit ?? 'ຊິ້ນ'} (ຕ່ຳກວ່າຄ່າຂັ້ນຕ່ຳ ${Number(item.lowStockThreshold)})`,
        data: {
          productId: item.productId,
          quantity: Number(item.quantity),
          threshold: Number(item.lowStockThreshold),
        },
      });

      this.logger.log(
        `Low-stock alert created: ${item.product.name} qty=${item.quantity} tenant=${item.tenantId}`,
      );
    }
  }
}
