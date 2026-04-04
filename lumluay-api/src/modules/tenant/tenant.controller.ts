import { Controller, Get, Patch, Body, UseGuards } from '@nestjs/common';
import { TenantService } from './tenant.service';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { UpdateTenantDto } from './dto/tenant.dto';

@Controller('tenant')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TenantController {
  constructor(private readonly tenantService: TenantService) {}

  @Get()
  getTenant(@TenantId() tenantId: string) {
    return this.tenantService.getTenantProfile(tenantId);
  }

  @Patch()
  @Roles('owner', 'manager')
  updateTenant(@TenantId() tenantId: string, @Body() dto: UpdateTenantDto) {
    return this.tenantService.update(tenantId, dto);
  }
}