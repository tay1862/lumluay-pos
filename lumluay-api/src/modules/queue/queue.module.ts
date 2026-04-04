import { Module } from '@nestjs/common';
import { DatabaseModule } from '@/database/database.module';
import { QueueService } from './queue.service';
import { QueueController } from './queue.controller';

@Module({
  imports: [DatabaseModule],
  controllers: [QueueController],
  providers: [QueueService],
  exports: [QueueService],
})
export class QueueModule {}
