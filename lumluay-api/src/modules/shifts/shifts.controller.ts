import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  ParseUUIDPipe,
  UseGuards,
} from '@nestjs/common';
import { ShiftsService } from './shifts.service';
import { OpenShiftDto, CloseShiftDto } from './dto/shift.dto';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { CurrentUser } from '@/common/decorators/user.decorator';
import { AuthUser } from '@/common/decorators/user.decorator';

@Controller('shifts')
@UseGuards(JwtAuthGuard)
export class ShiftsController {
  constructor(private readonly shiftsService: ShiftsService) {}

  @Get()
  findAll(@TenantId() tenantId: string) {
    return this.shiftsService.findAll(tenantId);
  }

  @Get('current')
  getCurrent(@TenantId() tenantId: string) {
    return this.shiftsService.getCurrent(tenantId);
  }

  @Get(':id')
  findOne(@TenantId() tenantId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.shiftsService.findOne(tenantId, id);
  }

  @Post('open')
  open(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Body() dto: OpenShiftDto,
  ) {
    return this.shiftsService.open(tenantId, user.id, dto);
  }

  @Post('close')
  close(@TenantId() tenantId: string, @Body() dto: CloseShiftDto) {
    return this.shiftsService.close(tenantId, dto);
  }
}
