import { Module } from '@nestjs/common';
import { DatabaseModule } from '@/database/database.module';
import { ImportExportService } from './import-export.service';
import { ImportExportController } from './import-export.controller';

@Module({
  imports: [DatabaseModule],
  controllers: [ImportExportController],
  providers: [ImportExportService],
})
export class ImportExportModule {}
