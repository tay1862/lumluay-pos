import {
  Controller, Get, Post, Patch, Delete,
  Body, Param, ParseUUIDPipe, Query, UseGuards, HttpCode, HttpStatus,
} from '@nestjs/common';
import { IsOptional, IsString, IsInt, Min } from 'class-validator';
import { Type } from 'class-transformer';

class OrdersQueryDto {
  @IsOptional() @IsString() status?: string;
  @IsOptional() @IsInt() @Min(1) @Type(() => Number) limit?: number;
  @IsOptional() @IsInt() @Min(0) @Type(() => Number) offset?: number;
}
import { OrdersService } from './orders.service';
import {
  CreateOrderDto,
  AddOrderItemDto,
  ApplyDiscountDto,
  UpdateOrderItemDto,
  SendToKitchenDto,
  VoidOrderDto,
  VoidOrderItemDto,
} from './dto/order.dto';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { CurrentUser } from '@/common/decorators/user.decorator';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { AuthUser } from '@/common/decorators/user.decorator';

@Controller('orders')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Get()
  findAll(
    @TenantId() tenantId: string,
    @Query() query: OrdersQueryDto,
  ) {
    return this.ordersService.findAll(tenantId, query);
  }

  @Get(':id')
  findOne(@TenantId() tenantId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.findOne(tenantId, id);
  }

  @Post()
  create(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateOrderDto,
  ) {
    return this.ordersService.create(tenantId, user.id, dto);
  }

  @Post(':id/items')
  addItem(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddOrderItemDto,
  ) {
    return this.ordersService.addItem(tenantId, id, dto);
  }

  @Patch(':id/items/:itemId')
  updateItem(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('itemId', ParseUUIDPipe) itemId: string,
    @Body() dto: UpdateOrderItemDto,
  ) {
    return this.ordersService.updateItem(tenantId, id, itemId, dto);
  }

  @Delete(':id/items/:itemId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeItem(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('itemId', ParseUUIDPipe) itemId: string,
  ) {
    return this.ordersService.removeItem(tenantId, id, itemId);
  }

  @Post(':id/confirm')
  @HttpCode(HttpStatus.OK)
  confirm(@TenantId() tenantId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.confirm(tenantId, id);
  }

  @Post(':id/cancel')
  @HttpCode(HttpStatus.OK)
  cancel(@TenantId() tenantId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.cancel(tenantId, id);
  }

  @Patch(':id/discount')
  applyDiscount(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ApplyDiscountDto,
  ) {
    return this.ordersService.applyDiscount(tenantId, id, dto);
  }

  @Post(':id/hold')
  @HttpCode(HttpStatus.OK)
  hold(@TenantId() tenantId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.hold(tenantId, id);
  }

  @Post(':id/resume')
  @HttpCode(HttpStatus.OK)
  resume(@TenantId() tenantId: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.ordersService.resume(tenantId, id);
  }

  @Post(':id/void')
  @Roles('owner', 'manager')
  @HttpCode(HttpStatus.OK)
  voidOrder(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: VoidOrderDto,
  ) {
    return this.ordersService.voidOrder(tenantId, id, user.id, dto);
  }

  @Post(':id/void-item')
  @Roles('owner', 'manager')
  @HttpCode(HttpStatus.OK)
  voidOrderItem(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: VoidOrderItemDto,
  ) {
    return this.ordersService.voidOrderItem(tenantId, id, user.id, dto);
  }

  @Post(':id/send-to-kitchen')
  @HttpCode(HttpStatus.OK)
  sendToKitchen(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SendToKitchenDto,
  ) {
    return this.ordersService.sendToKitchen(tenantId, id, dto);
  }
}
