import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { AdminService } from './admin.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('super_admin')
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  getStats() {
    return this.adminService.getSystemStats();
  }

  @Get('dashboard')
  getDashboard() {
    return this.adminService.getDashboard();
  }

  @Get('tenants')
  listTenants(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.listTenants(
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Get('tenants/:id')
  getTenant(@Param('id', ParseUUIDPipe) id: string) {
    return this.adminService.getTenantDetails(id);
  }

  @Patch('tenants/:id')
  updateTenant(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: { name?: string; isActive?: boolean; subscriptionExpiresAt?: string },
  ) {
    return this.adminService.updateTenant(id, {
      ...body,
      subscriptionExpiresAt: body.subscriptionExpiresAt
        ? new Date(body.subscriptionExpiresAt)
        : undefined,
    });
  }

  @Patch('tenants/:id/active')
  setActive(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('isActive') isActive: boolean,
  ) {
    return this.adminService.setTenantActive(id, isActive);
  }

  @Get('plans')
  listPlans() {
    return this.adminService.listPlans();
  }

  @Post('plans')
  createPlan(@Body() body: {
    name: string;
    slug: string;
    description?: string;
    monthlyPrice: number;
    yearlyPrice?: number;
    maxUsers?: number;
    maxProducts?: number;
    maxBranches?: number;
    features?: string[];
  }) {
    return this.adminService.createPlan(body);
  }

  @Patch('plans/:id')
  updatePlan(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: {
      name?: string;
      description?: string;
      monthlyPrice?: number;
      yearlyPrice?: number;
      maxUsers?: number;
      maxProducts?: number;
      maxBranches?: number;
      features?: string[];
      isActive?: boolean;
    },
  ) {
    return this.adminService.updatePlan(id, body);
  }

  @Delete('plans/:id')
  deletePlan(@Param('id', ParseUUIDPipe) id: string) {
    return this.adminService.deletePlan(id);
  }
}
