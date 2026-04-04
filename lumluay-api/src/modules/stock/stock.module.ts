import { Module } from '@nestjs/common';
import { StockService } from './stock.service';
import { StockController } from './stock.controller';
import { StockAlertJob } from './stock-alert.job';
import { NotificationsModule } from '@/modules/notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [StockController],
  providers: [StockService, StockAlertJob],
  exports: [StockService],
})
export class StockModule {}
