import {
  IsString,
  IsBoolean,
  IsNumber,
  IsOptional,
  Min,
  Max,
  IsInt,
  IsArray,
  IsIn,
  IsUUID,
  IsObject,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateSettingsDto {
  @IsOptional()
  @IsString()
  receiptHeader?: string;

  @IsOptional()
  @IsString()
  receiptFooter?: string;

  @IsOptional()
  @IsBoolean()
  receiptShowLogo?: boolean;

  @IsOptional()
  @IsInt()
  receiptWidth?: number;

  @IsOptional()
  @IsBoolean()
  taxIncluded?: boolean;

  @IsOptional()
  @IsBoolean()
  serviceChargeEnabled?: boolean;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  serviceChargePercent?: number;

  @IsOptional()
  @IsBoolean()
  requireTableForDineIn?: boolean;

  @IsOptional()
  @IsBoolean()
  allowSplitBill?: boolean;

  @IsOptional()
  @IsBoolean()
  allowDiscount?: boolean;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  maxDiscountPercent?: number;

  @IsOptional()
  @IsBoolean()
  allowRefund?: boolean;

  @IsOptional()
  @IsBoolean()
  kitchenPrintEnabled?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  lowStockThreshold?: number;
}

export class CreateTaxRateDto {
  @IsString()
  name: string;

  @IsNumber()
  @Min(0)
  @Max(100)
  rate: number;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class UpdateTaxRateDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  rate?: number;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateCurrenciesDto {
  @IsString()
  @IsOptional()
  defaultCurrency?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  enabledCurrencies?: string[];

  @IsOptional()
  @IsObject()
  decimals?: Record<string, number>;
}

export class UpdateExchangeRatesDto {
  @IsObject()
  rates: Record<string, number>;
}

export class UpdateReceiptSettingsDto {
  @IsOptional()
  @IsString()
  header?: string;

  @IsOptional()
  @IsString()
  footer?: string;

  @IsOptional()
  @IsString()
  prefix?: string;

  @IsOptional()
  @IsInt()
  @IsIn([58, 80])
  width?: number;

  @IsOptional()
  @IsBoolean()
  showLogo?: boolean;
}

export class CreatePrinterDto {
  @IsString()
  name: string;

  @IsString()
  @IsIn(['bluetooth', 'usb', 'wifi'])
  type: 'bluetooth' | 'usb' | 'wifi';

  @IsOptional()
  @IsString()
  ipAddress?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  port?: number;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class UpdatePrinterDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  @IsIn(['bluetooth', 'usb', 'wifi'])
  type?: 'bluetooth' | 'usb' | 'wifi';

  @IsOptional()
  @IsString()
  ipAddress?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  port?: number;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class SeedSampleDataDto {
  @IsOptional()
  @IsBoolean()
  clearExisting?: boolean;
}
