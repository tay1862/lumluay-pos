import {
  Controller, Get, Post, Param, ParseUUIDPipe, Body, UseGuards,
} from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { CreatePaymentDto, CompleteOrderDto, RefundOrderDto } from './dto/payment.dto';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { CurrentUser, AuthUser } from '@/common/decorators/user.decorator';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';

@Controller()
@UseGuards(JwtAuthGuard)
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Get('payments/order/:orderId')
  findByOrder(
    @TenantId() tenantId: string,
    @Param('orderId', ParseUUIDPipe) orderId: string,
  ) {
    return this.paymentsService.findByOrder(tenantId, orderId);
  }

  @Post('payments')
  create(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Body() dto: CreatePaymentDto,
  ) {
    // Legacy endpoint compatibility
    const payload = dto as CreatePaymentDto & { orderId?: string };
    return this.paymentsService.create(tenantId, user.id, payload.orderId ?? '', dto);
  }

  @Post('orders/:orderId/payments')
  createForOrder(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body() dto: CreatePaymentDto,
  ) {
    return this.paymentsService.create(tenantId, user.id, orderId, dto);
  }

  @Post('orders/:orderId/complete')
  completeOrder(
    @TenantId() tenantId: string,
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body() dto: CompleteOrderDto,
  ) {
    return this.paymentsService.completeOrder(tenantId, orderId, dto);
  }

  @Post('orders/:orderId/refund')
  refundOrder(
    @TenantId() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body() dto: RefundOrderDto,
  ) {
    return this.paymentsService.refundOrder(tenantId, user.id, orderId, dto);
  }
}
