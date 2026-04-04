import {
  Controller, Get, Post, Patch, Delete, Body, Param, ParseUUIDPipe, UseGuards,
} from '@nestjs/common';
import {
  TablesService,
  CreateTableDto,
  UpdateTableDto,
  MoveTableDto,
  MergeTablesDto,
  SplitTableDto,
  CreateZoneDto,
  UpdateZoneDto,
} from './tables.service';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';

@Controller('tables')
@UseGuards(JwtAuthGuard)
export class TablesController {
  constructor(private readonly tablesService: TablesService) {}

  @Get()
  findAll(@TenantId() tenantId: string) {
    return this.tablesService.findAll(tenantId);
  }

  @Get('zones')
  findZones(@TenantId() tenantId: string) {
    return this.tablesService.findZones(tenantId);
  }

  @Post('zones')
  createZone(@TenantId() tenantId: string, @Body() dto: CreateZoneDto) {
    return this.tablesService.createZone(tenantId, dto);
  }

  @Patch('zones/:id')
  updateZone(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateZoneDto,
  ) {
    return this.tablesService.updateZone(tenantId, id, dto);
  }

  @Delete('zones/:id')
  deleteZone(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tablesService.deleteZone(tenantId, id);
  }

  @Get(':id')
  findOne(@TenantId() tenantId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.tablesService.findOne(tenantId, id);
  }

  @Post()
  create(@TenantId() tenantId: string, @Body() dto: CreateTableDto) {
    return this.tablesService.create(tenantId, dto);
  }

  @Patch(':id')
  update(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateTableDto,
  ) {
    return this.tablesService.update(tenantId, id, dto);
  }

  @Patch(':id/status')
  setStatus(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body('status') status: 'available' | 'occupied' | 'reserved' | 'cleaning',
  ) {
    return this.tablesService.setStatus(tenantId, id, status);
  }

  @Post(':id/move')
  moveTable(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: MoveTableDto,
  ) {
    return this.tablesService.moveTable(tenantId, id, dto);
  }

  @Post('merge')
  mergeTables(
    @TenantId() tenantId: string,
    @Body() dto: MergeTablesDto,
  ) {
    return this.tablesService.mergeTables(tenantId, dto);
  }

  @Post(':id/merge')
  mergeTablesCompatibility(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: Omit<MergeTablesDto, 'targetTableId' | 'target_table_id'>,
  ) {
    return this.tablesService.mergeTables(tenantId, {
      ...dto,
      targetTableId: id,
    });
  }

  @Post(':id/split')
  splitTable(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SplitTableDto,
  ) {
    return this.tablesService.splitTable(tenantId, id, dto);
  }

  @Get(':id/qr-code')
  generateQrCode(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tablesService.generateTableQrCode(tenantId, id);
  }
}
