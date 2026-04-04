import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { KitchenService } from './kitchen.service';
import { KitchenController } from './kitchen.controller';
import { KitchenGateway } from './kitchen.gateway';

@Module({
  imports: [JwtModule.register({})],
  controllers: [KitchenController],
  providers: [KitchenService, KitchenGateway],
  exports: [KitchenService, KitchenGateway],
})
export class KitchenModule {}
