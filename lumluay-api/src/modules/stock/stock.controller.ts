import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { StockService, AdjustStockDto } from './stock.service';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { CurrentUser, AuthUser } from '@/common/decorators/user.decorator';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';

@Controller('stock')
@UseGuards(JwtAuthGuard, RolesGuard)
export class StockController {
  constructor(private readonly stockService: StockService) {}

  @Get('levels')
  findLevels(@TenantId() tenantId: string) {
    return this.stockService.findLevels(tenantId);
  }

  @Get('movements')
  @Roles('owner', 'manager')
  findMovements(@TenantId() tenantId: string) {
    return this.stockService.findMovements(tenantId);
  }

  @Post('adjust')
  @Roles('owner', 'manager')
  adjust(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Body() dto: AdjustStockDto,
  ) {
    return this.stockService.adjust(tenantId, user.id, dto);
  }
}
