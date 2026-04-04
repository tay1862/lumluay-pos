import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Res,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { FastifyReply } from 'fastify';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { TenantId } from '@/common/decorators/tenant.decorator';
import { ImportExportService } from './import-export.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('owner', 'manager')
@Controller('import-export')
export class ImportExportController {
  constructor(private readonly importExportService: ImportExportService) {}

  // ─── Templates (17.7.4) ────────────────────────────────────────────────────

  /** Download a blank CSV template for bulk product import. */
  @Get('template/products')
  downloadProductTemplate(@Res() reply: FastifyReply) {
    const headers = [
      'name',
      'sku',
      'barcode',
      'basePrice',
      'unit',
      'productType',
      'description',
      'categoryName',
    ];
    const example = [
      'Sample Product',
      'SKU-001',
      '8850001234567',
      '59.00',
      'ชิ้น',
      'simple',
      'คำอธิบายสินค้า',
      'เครื่องดื่ม',
    ];
    const csv = [headers.join(','), example.join(',')].join('\n');
    reply
      .header('Content-Type', 'text/csv; charset=utf-8')
      .header(
        'Content-Disposition',
        'attachment; filename="products-import-template.csv"',
      )
      .send('\uFEFF' + csv); // BOM for Excel UTF-8 compatibility
  }

  // ─── Exports ───────────────────────────────────────────────────────────────

  @Get('export/products')
  async exportProducts(
    @TenantId() tenantId: string,
    @Res() reply: FastifyReply,
  ) {
    const csv = await this.importExportService.exportProducts(tenantId);
    reply
      .header('Content-Type', 'text/csv')
      .header('Content-Disposition', 'attachment; filename="products.csv"')
      .send(csv);
  }

  @Get('export/members')
  async exportMembers(
    @TenantId() tenantId: string,
    @Res() reply: FastifyReply,
  ) {
    const csv = await this.importExportService.exportMembers(tenantId);
    reply
      .header('Content-Type', 'text/csv')
      .header('Content-Disposition', 'attachment; filename="members.csv"')
      .send(csv);
  }

  // ─── Imports ───────────────────────────────────────────────────────────────

  @Post('import/:entity')
  async import(
    @TenantId() tenantId: string,
    @Param('entity') entity: string,
    @Body() body: { csv: string },
  ) {
    if (!body.csv) throw new BadRequestException('csv field is required');

    switch (entity) {
      case 'products':
        return this.importExportService.importProducts(tenantId, body.csv);
      default:
        throw new BadRequestException(`Import for "${entity}" not supported`);
    }
  }
}
