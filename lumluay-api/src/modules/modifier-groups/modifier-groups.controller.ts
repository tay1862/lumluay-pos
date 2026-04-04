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
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ModifierGroupsService } from './modifier-groups.service';
import {
  CreateModifierGroupDto,
  UpdateModifierGroupDto,
  CreateModifierOptionDto,
  UpdateModifierOptionDto,
} from './dto/modifier-group.dto';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { TenantId } from '@/common/decorators/tenant.decorator';

@Controller('modifier-groups')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ModifierGroupsController {
  constructor(private readonly service: ModifierGroupsService) {}

  @Get()
  findAll(@TenantId() tenantId: string) {
    return this.service.findAll(tenantId);
  }

  @Get(':id')
  findOne(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.findOne(tenantId, id);
  }

  @Post()
  @Roles('owner', 'manager')
  create(@TenantId() tenantId: string, @Body() dto: CreateModifierGroupDto) {
    return this.service.create(tenantId, dto);
  }

  @Patch(':id')
  @Roles('owner', 'manager')
  update(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateModifierGroupDto,
  ) {
    return this.service.update(tenantId, id, dto);
  }

  @Delete(':id')
  @Roles('owner', 'manager')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.remove(tenantId, id);
  }

  // ─── Options ──────────────────────────────────────────────────────────────

  @Post(':id/options')
  @Roles('owner', 'manager')
  addOption(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) groupId: string,
    @Body() dto: CreateModifierOptionDto,
  ) {
    return this.service.addOption(tenantId, groupId, dto);
  }

  @Patch(':id/options/:optionId')
  @Roles('owner', 'manager')
  updateOption(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) groupId: string,
    @Param('optionId', ParseUUIDPipe) optionId: string,
    @Body() dto: UpdateModifierOptionDto,
  ) {
    return this.service.updateOption(tenantId, groupId, optionId, dto);
  }

  @Delete(':id/options/:optionId')
  @Roles('owner', 'manager')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeOption(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) groupId: string,
    @Param('optionId', ParseUUIDPipe) optionId: string,
  ) {
    return this.service.removeOption(tenantId, groupId, optionId);
  }
}
