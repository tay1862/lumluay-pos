import {
  Controller,
  Get,
  Patch,
  Post,
  Delete,
  Body,
  Param,
  ParseUUIDPipe,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { SettingsService } from './settings.service';
import {
  UpdateSettingsDto,
  CreateTaxRateDto,
  UpdateTaxRateDto,
  UpdateCurrenciesDto,
  UpdateExchangeRatesDto,
  UpdateReceiptSettingsDto,
  CreatePrinterDto,
  UpdatePrinterDto,
  SeedSampleDataDto,
} from './dto/settings.dto';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { TenantId } from '@/common/decorators/tenant.decorator';

@Controller('settings')
@UseGuards(JwtAuthGuard, RolesGuard)
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get()
  getSettings(@TenantId() tenantId: string) {
    return this.settingsService.getSettings(tenantId);
  }

  @Patch()
  @Roles('owner', 'manager')
  updateSettings(@TenantId() tenantId: string, @Body() dto: UpdateSettingsDto) {
    return this.settingsService.updateSettings(tenantId, dto);
  }

  // ── Tax Rates ──────────────────────────────────────────────────────────────

  @Get('tax-rates')
  getTaxRates(@TenantId() tenantId: string) {
    return this.settingsService.getTaxRates(tenantId);
  }

  @Post('tax-rates')
  @Roles('owner', 'manager')
  createTaxRate(@TenantId() tenantId: string, @Body() dto: CreateTaxRateDto) {
    return this.settingsService.createTaxRate(tenantId, dto);
  }

  @Patch('tax-rates/:id')
  @Roles('owner', 'manager')
  updateTaxRate(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateTaxRateDto,
  ) {
    return this.settingsService.updateTaxRate(tenantId, id, dto);
  }

  @Delete('tax-rates/:id')
  @Roles('owner')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteTaxRate(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.settingsService.deleteTaxRate(tenantId, id);
  }

  // ── Currencies & Exchange Rates ───────────────────────────────────────────

  @Get('currencies')
  getCurrencies(@TenantId() tenantId: string) {
    return this.settingsService.getCurrencies(tenantId);
  }

  @Patch('currencies')
  @Roles('owner', 'manager')
  updateCurrencies(
    @TenantId() tenantId: string,
    @Body() dto: UpdateCurrenciesDto,
  ) {
    return this.settingsService.updateCurrencies(tenantId, dto);
  }

  @Patch('exchange-rates')
  @Roles('owner', 'manager')
  updateExchangeRates(
    @TenantId() tenantId: string,
    @Body() dto: UpdateExchangeRatesDto,
  ) {
    return this.settingsService.updateExchangeRates(tenantId, dto);
  }

  // ── Receipt Settings ───────────────────────────────────────────────────────

  @Get('receipt')
  getReceiptSettings(@TenantId() tenantId: string) {
    return this.settingsService.getReceiptSettings(tenantId);
  }

  @Patch('receipt')
  @Roles('owner', 'manager')
  updateReceiptSettings(
    @TenantId() tenantId: string,
    @Body() dto: UpdateReceiptSettingsDto,
  ) {
    return this.settingsService.updateReceiptSettings(tenantId, dto);
  }

  // ── Printer Config ─────────────────────────────────────────────────────────

  @Get('printers')
  getPrinters(@TenantId() tenantId: string) {
    return this.settingsService.getPrinters(tenantId);
  }

  @Post('printers')
  @Roles('owner', 'manager')
  createPrinter(@TenantId() tenantId: string, @Body() dto: CreatePrinterDto) {
    return this.settingsService.createPrinter(tenantId, dto);
  }

  @Patch('printers/:id')
  @Roles('owner', 'manager')
  updatePrinter(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdatePrinterDto,
  ) {
    return this.settingsService.updatePrinter(tenantId, id, dto);
  }

  @Delete('printers/:id')
  @Roles('owner', 'manager')
  @HttpCode(HttpStatus.NO_CONTENT)
  deletePrinter(
    @TenantId() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.settingsService.deletePrinter(tenantId, id);
  }

  @Post('sample-data/seed')
  @Roles('owner', 'manager')
  seedSampleData(
    @TenantId() tenantId: string,
    @Body() dto: SeedSampleDataDto,
  ) {
    return this.settingsService.seedSampleData(tenantId, dto.clearExisting ?? false);
  }
}
