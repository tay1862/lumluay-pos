import { Controller, Get, Post, Param, Headers, Body } from '@nestjs/common';
import { PublicService } from './public.service';

@Controller('public')
export class PublicController {
  constructor(private readonly publicService: PublicService) {}

  // 17.8.2 — Menu
  @Get('menu/:slug')
  getMenu(@Param('slug') slug: string) {
    return this.publicService.getMenuBySlug(slug);
  }

  // 17.8.3 — QR order
  @Post('menu/:slug/orders')
  createOrder(
    @Param('slug') slug: string,
    @Body() body: { tableId?: string; items: Array<{ productId: string; quantity: number; note?: string }> },
  ) {
    return this.publicService.createQrOrder(slug, body);
  }

  @Get('queue')
  getQueueStatus(@Headers('x-tenant-id') tenantId: string) {
    return this.publicService.getQueueStatus(tenantId);
  }
}
