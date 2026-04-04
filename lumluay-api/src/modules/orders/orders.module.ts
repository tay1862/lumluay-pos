import { Module } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { OrderCalculationService } from './order-calculation.service';
import { KitchenModule } from '@/modules/kitchen/kitchen.module';

@Module({
  imports: [KitchenModule],
  controllers: [OrdersController],
  providers: [OrdersService, OrderCalculationService],
  exports: [OrdersService, OrderCalculationService],
})
export class OrdersModule {}
