import { Module } from '@nestjs/common';
import { DatabaseModule } from '@/database/database.module';
import { PublicService } from './public.service';
import { PublicController } from './public.controller';

@Module({
  imports: [DatabaseModule],
  controllers: [PublicController],
  providers: [PublicService],
})
export class PublicModule {}
