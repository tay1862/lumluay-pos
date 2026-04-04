import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  ParseUUIDPipe,
  UseGuards,
} from '@nestjs/common';
import {
  TablesService,
  CreateZoneDto,
  UpdateZoneDto,
} from './tables.service';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';

@Controller('zones')
@UseGuards(JwtAuthGuard)
export class ZonesController {
  constructor(private readonly tablesService: TablesService) {}

  @Get()
  findAll(@TenantId() tenantId: string) {
    return this.tablesService.findZones(tenantId);
  }

  @Get(':id')
  findOne(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tablesService.findZone(tenantId, id);
  }

  @Post()
  create(@TenantId() tenantId: string, @Body() dto: CreateZoneDto) {
    return this.tablesService.createZone(tenantId, dto);
  }

  @Patch(':id')
  update(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateZoneDto,
  ) {
    return this.tablesService.updateZone(tenantId, id, dto);
  }

  @Delete(':id')
  remove(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tablesService.deleteZone(tenantId, id);
  }
}
