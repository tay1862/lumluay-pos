import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { CurrentUser, AuthUser } from '@/common/decorators/user.decorator';
import { SyncService } from './sync.service';
import { PushSyncDto, PullSyncDto } from './dto/sync.dto';

@UseGuards(JwtAuthGuard)
@Controller('sync')
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Get('pull')
  pull(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Query('deviceId') deviceId: string,
    @Query('since') since?: string,
  ) {
    return this.syncService.pull(tenantId, user.id, { deviceId, since });
  }

  @Post('push')
  push(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Body() dto: PushSyncDto,
  ) {
    return this.syncService.push(tenantId, user.id, dto);
  }

  @Post('acknowledge')
  acknowledge(
    @TenantId() tenantId: string,
    @Body() body: { ids: string[] },
  ) {
    return this.syncService.acknowledge(tenantId, body.ids);
  }

  @Get('status')
  getStatus(
    @TenantId() tenantId: string,
    @Query('deviceId') deviceId: string,
  ) {
    return this.syncService.getStatus(tenantId, deviceId);
  }
}
