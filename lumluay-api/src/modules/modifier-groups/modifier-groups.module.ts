import { Module } from '@nestjs/common';
import { ModifierGroupsController } from './modifier-groups.controller';
import { ModifierGroupsService } from './modifier-groups.service';
import { DatabaseModule } from '@/database/database.module';

@Module({
  imports: [DatabaseModule],
  controllers: [ModifierGroupsController],
  providers: [ModifierGroupsService],
  exports: [ModifierGroupsService],
})
export class ModifierGroupsModule {}
