import {
  Controller,
  Get,
  Patch,
  Param,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { CurrentUser, AuthUser } from '@/common/decorators/user.decorator';
import { NotificationsService } from './notifications.service';

@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  findAll(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Query('unread') unread?: string,
  ) {
    return this.notificationsService.findForUser(
      tenantId,
      user.id,
      unread === 'true',
    );
  }

  @Get('unread-count')
  getUnreadCount(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
  ) {
    return this.notificationsService.getUnreadCount(tenantId, user.id);
  }

  @Patch(':id/read')
  markRead(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.notificationsService.markRead(tenantId, user.id, id);
  }

  @Patch('read-all')
  markAllRead(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
  ) {
    return this.notificationsService.markAllRead(tenantId, user.id);
  }
}
