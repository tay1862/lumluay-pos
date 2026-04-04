import { Module } from '@nestjs/common';
import { DatabaseModule } from '@/database/database.module';
import { SyncService } from './sync.service';
import { SyncController } from './sync.controller';
import { ConflictResolverService } from './conflict-resolver.service';

@Module({
  imports: [DatabaseModule],
  controllers: [SyncController],
  providers: [SyncService, ConflictResolverService],
  exports: [SyncService],
})
export class SyncModule {}
