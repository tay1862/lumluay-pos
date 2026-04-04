import { Module } from '@nestjs/common';
import { ProductsService } from './products.service';
import { ProductsController } from './products.controller';
import { ModifierGroupsModule } from '@/modules/modifier-groups/modifier-groups.module';
import { DatabaseModule } from '@/database/database.module';

@Module({
  imports: [DatabaseModule, ModifierGroupsModule],
  controllers: [ProductsController],
  providers: [ProductsService],
  exports: [ProductsService],
})
export class ProductsModule {}
