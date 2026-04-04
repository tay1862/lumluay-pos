import { Module } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { PaymentsController } from './payments.controller';
import { ExchangeRateService } from './exchange-rate.service';
import { SettingsModule } from '@/modules/settings/settings.module';
import { NotificationsModule } from '@/modules/notifications/notifications.module';
import { CouponsModule } from '@/modules/coupons/coupons.module';

@Module({
  imports: [SettingsModule, NotificationsModule, CouponsModule],
  controllers: [PaymentsController],
  providers: [PaymentsService, ExchangeRateService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
