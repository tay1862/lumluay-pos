import {
  IsEnum, IsNumber, IsOptional, IsString, IsUUID, Min,
  IsArray, ValidateNested, IsBoolean, ArrayMinSize,
} from 'class-validator';
import { Type } from 'class-transformer';

export enum PaymentMethodDto {
  CASH = 'cash',
  CREDIT_CARD = 'credit_card',
  DEBIT_CARD = 'debit_card',
  QR_PROMPTPAY = 'qr_promptpay',
  BANK_TRANSFER = 'bank_transfer',
  WALLET_TRUEMONEY = 'wallet_truemoney',
  WALLET_LINEPAY = 'wallet_linepay',
  MEMBER_POINTS = 'member_points',
}

export class CreatePaymentDto {
  @IsOptional()
  @IsUUID()
  orderId?: string;

  @IsEnum(PaymentMethodDto)
  method: PaymentMethodDto;

  @IsNumber()
  @Min(0)
  amount: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  tendered?: number;

  @IsOptional()
  @IsString()
  reference?: string;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  exchangeRate?: number;
}

// ─── Split Payment DTO (batch multiple payments in one call) ─────────────────
export class SplitPaymentItemDto {
  @IsEnum(PaymentMethodDto)
  method: PaymentMethodDto;

  @IsNumber()
  @Min(0)
  amount: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  tendered?: number;

  @IsOptional()
  @IsString()
  reference?: string;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  exchangeRate?: number;
}

export class SplitPaymentDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SplitPaymentItemDto)
  @ArrayMinSize(1)
  payments: SplitPaymentItemDto[];

  @IsOptional()
  @IsBoolean()
  autoComplete?: boolean;
}

export class CompleteOrderDto {
  @IsOptional()
  @IsString()
  note?: string;
}

export class RefundOrderDto {
  @IsOptional()
  @IsNumber()
  @Min(0)
  amount?: number;

  @IsOptional()
  @IsString()
  reason?: string;
}
