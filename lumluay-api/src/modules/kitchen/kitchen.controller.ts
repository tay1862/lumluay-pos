import {
  Controller, Get, Post, Param, ParseUUIDPipe, Query, UseGuards,
} from '@nestjs/common';
import { KitchenService } from './kitchen.service';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';

@Controller('kitchen')
@UseGuards(JwtAuthGuard)
export class KitchenController {
  constructor(private readonly kitchenService: KitchenService) {}

  @Get('tickets')
  findPending(
    @TenantId() tenantId: string,
    @Query('station') station?: string,
  ) {
    return this.kitchenService.findPending(tenantId, station);
  }

  @Post('tickets/:id/preparing')
  startPreparing(@TenantId() tenantId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.kitchenService.startPreparing(tenantId, id);
  }

  @Post('tickets/:id/ready')
  markReady(@TenantId() tenantId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.kitchenService.markReady(tenantId, id);
  }

  @Post('tickets/:id/served')
  markServed(@TenantId() tenantId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.kitchenService.markServed(tenantId, id);
  }
}
