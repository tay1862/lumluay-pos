import { Module } from '@nestjs/common';
import { TablesService } from './tables.service';
import { TablesController } from './tables.controller';
import { ZonesController } from './zones.controller';
import { OrdersModule } from '@/modules/orders/orders.module';

@Module({
  imports: [OrdersModule],
  controllers: [TablesController, ZonesController],
  providers: [TablesService],
  exports: [TablesService],
})
export class TablesModule {}
