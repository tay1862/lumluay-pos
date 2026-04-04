import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  ParseUUIDPipe,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { QueueService } from './queue.service';
import { CreateQueueEntryDto, UpdateQueueStatusDto } from './dto/queue.dto';

@UseGuards(JwtAuthGuard)
@Controller('queue')
export class QueueController {
  constructor(private readonly queueService: QueueService) {}

  @Get()
  findAll(@TenantId() tenantId: string, @Query('date') date?: string) {
    return this.queueService.findAll(tenantId, date);
  }

  @Get('active')
  findActive(@TenantId() tenantId: string) {
    return this.queueService.findActive(tenantId);
  }

  @Get('stats')
  getStats(@TenantId() tenantId: string) {
    return this.queueService.getStats(tenantId);
  }

  @Get(':id')
  findOne(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.queueService.findOne(tenantId, id);
  }

  @Post()
  create(@TenantId() tenantId: string, @Body() dto: CreateQueueEntryDto) {
    return this.queueService.create(tenantId, dto);
  }

  @Patch(':id/status')
  updateStatus(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateQueueStatusDto,
  ) {
    return this.queueService.updateStatus(tenantId, id, dto);
  }
}
