import {
  Controller,
  Get,
  Query,
  UseGuards,
  BadRequestException,
  Res,
  Header,
} from '@nestjs/common';
import { Response } from 'express';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { ReportsService } from './reports.service';

function parseDateRange(from?: string, to?: string): [Date, Date] {
  const now = new Date();
  const start = from ? new Date(from) : new Date(now.getFullYear(), now.getMonth(), 1);
  const end = to ? new Date(to) : now;
  if (isNaN(start.getTime()) || isNaN(end.getTime()))
    throw new BadRequestException('Invalid date range');
  end.setHours(23, 59, 59, 999);
  return [start, end];
}

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('owner', 'manager')
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('summary')
  getSummary(
    @TenantId() tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const [start, end] = parseDateRange(from, to);
    return this.reportsService.getSummary(tenantId, start, end);
  }

  @Get('daily')
  getDaily(
    @TenantId() tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const [start, end] = parseDateRange(from, to);
    return this.reportsService.getDailyBreakdown(tenantId, start, end);
  }

  @Get('top-products')
  getTopProducts(
    @TenantId() tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('limit') limit?: string,
  ) {
    const [start, end] = parseDateRange(from, to);
    return this.reportsService.getTopProducts(tenantId, start, end, limit ? parseInt(limit) : 20);
  }

  @Get('hourly')
  getHourly(
    @TenantId() tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const [start, end] = parseDateRange(from, to);
    return this.reportsService.getHourlyBreakdown(tenantId, start, end);
  }

  @Get('stock')
  getStock(
    @TenantId() tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const [start, end] = parseDateRange(from, to);
    return this.reportsService.getStockReport(tenantId, start, end);
  }

  @Get('members')
  getMembers(
    @TenantId() tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const [start, end] = parseDateRange(from, to);
    return this.reportsService.getMembersReport(tenantId, start, end);
  }

  @Get('payment-methods')
  getPaymentMethods(
    @TenantId() tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const [start, end] = parseDateRange(from, to);
    return this.reportsService.getPaymentMethodReport(tenantId, start, end);
  }

  @Get('categories')
  getCategoryReport(
    @TenantId() tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const [start, end] = parseDateRange(from, to);
    return this.reportsService.getCategoryReport(tenantId, start, end);
  }

  // ─── 15.1.6 Sales grouped ────────────────────────────────────────────────────
  @Get('sales')
  getSalesReport(
    @TenantId() tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('groupBy') groupBy?: string,
  ) {
    const [start, end] = parseDateRange(from, to);
    const g = (['day', 'week', 'month'].includes(groupBy ?? '') ? groupBy : 'day') as
      | 'day'
      | 'week'
      | 'month';
    return this.reportsService.getSalesReport(tenantId, start, end, g);
  }

  // ─── 15.1.7 Products report ─────────────────────────────────────────────────
  @Get('products')
  getProductsReport(
    @TenantId() tenantId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('limit') limit?: string,
  ) {
    const [start, end] = parseDateRange(from, to);
    return this.reportsService.getProductsReport(
      tenantId, start, end,
      limit ? parseInt(limit, 10) : 100,
    );
  }

  // ─── 15.1.10 Export CSV ─────────────────────────────────────────────────────
  @Get('export')
  @Header('Content-Type', 'text/csv; charset=utf-8')
  async exportCsv(
    @TenantId() tenantId: string,
    @Query('type') type: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Res() res?: Response,
  ) {
    const [start, end] = parseDateRange(from, to);
    const reportType = (type === 'products' ? 'products' : 'sales') as
      | 'sales'
      | 'products';
    const csv = await this.reportsService.exportCsv(tenantId, start, end, reportType);
    const filename = `report-${reportType}-${start.toISOString().split('T')[0]}.csv`;
    res!.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res!.send(csv);
  }
}
