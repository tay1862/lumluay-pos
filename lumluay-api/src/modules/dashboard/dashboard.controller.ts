import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { DashboardService } from './dashboard.service';

@Controller('dashboard')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('owner', 'manager')
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('summary')
  getSummary(
    @TenantId() tenantId: string,
    @Query('date') date?: string,
  ) {
    return this.dashboardService.getSummary(
      tenantId,
      date ? new Date(date) : new Date(),
    );
  }

  @Get('hourly-sales')
  getHourlySales(
    @TenantId() tenantId: string,
    @Query('date') date?: string,
  ) {
    return this.dashboardService.getHourlySales(
      tenantId,
      date ? new Date(date) : new Date(),
    );
  }

  @Get('top-products')
  getTopProducts(
    @TenantId() tenantId: string,
    @Query('date') date?: string,
    @Query('limit') limit?: string,
  ) {
    return this.dashboardService.getTopProducts(
      tenantId,
      date ? new Date(date) : new Date(),
      limit ? parseInt(limit) : 10,
    );
  }

  @Get('sales-by-method')
  getSalesByMethod(
    @TenantId() tenantId: string,
    @Query('date') date?: string,
  ) {
    return this.dashboardService.getSalesByMethod(
      tenantId,
      date ? new Date(date) : new Date(),
    );
  }
}
