import {
  IsString, IsOptional, IsEnum, IsUUID, IsInt, IsNumber,
  IsArray, IsNotEmpty, Min, ValidateNested, Length,
} from 'class-validator';
import { Type } from 'class-transformer';

export enum OrderType {
  DINE_IN = 'dine_in',
  TAKEAWAY = 'takeaway',
  DELIVERY = 'delivery',
}

export enum DiscountType {
  AMOUNT = 'amount',
  PERCENT = 'percent',
  COUPON = 'coupon',
}

export class OrderItemModifierDto {
  @IsUUID()
  modifierOptionId: string;

  @IsInt()
  @Min(1)
  quantity: number = 1;
}

export class CreateOrderItemDto {
  @IsUUID()
  productId: string;

  @IsOptional()
  @IsUUID()
  variantId?: string;

  @IsInt()
  @Min(1)
  quantity: number;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  courseNumber?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemModifierDto)
  modifiers?: OrderItemModifierDto[];
}

export class CreateOrderDto {
  @IsOptional()
  @IsUUID()
  tableId?: string;

  @IsEnum(OrderType)
  @IsOptional()
  orderType?: OrderType = OrderType.DINE_IN;

  @IsOptional()
  @IsInt()
  @Min(1)
  guestCount?: number;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsUUID()
  customerId?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items?: CreateOrderItemDto[];
}

export class AddOrderItemDto {
  @IsUUID()
  productId: string;

  @IsOptional()
  @IsUUID()
  variantId?: string;

  @IsInt()
  @Min(1)
  quantity: number;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  courseNumber?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemModifierDto)
  modifiers?: OrderItemModifierDto[];
}

export class ApplyDiscountDto {
  @IsOptional()
  @IsEnum(DiscountType)
  type?: 'amount' | 'percent' | 'coupon' = 'amount';

  @IsNumber()
  @Min(0)
  amount: number;

  @IsOptional()
  @IsString()
  couponCode?: string;
}

export class UpdateOrderItemDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  quantity?: number;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  price?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemModifierDto)
  modifiers?: OrderItemModifierDto[];
}

export class VoidOrderDto {
  @IsString()
  @IsNotEmpty()
  reason: string;

  @IsString()
  @Length(4, 10)
  pin: string;
}

export class VoidOrderItemDto {
  @IsUUID()
  itemId: string;

  @IsString()
  @IsNotEmpty()
  reason: string;

  @IsString()
  @Length(4, 10)
  pin: string;
}

export class SendToKitchenDto {
  @IsOptional()
  @IsArray()
  @IsUUID(undefined, { each: true })
  itemIds?: string[];

  @IsOptional()
  @IsString()
  station?: string;
}
