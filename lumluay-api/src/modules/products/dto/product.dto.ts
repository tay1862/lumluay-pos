import {
  IsString, IsNotEmpty, IsOptional, IsBoolean, IsInt,
  IsUUID, IsEnum, IsNumber, Length, Min, IsBase64,
} from 'class-validator';

export enum ProductType {
  SIMPLE = 'simple',
  VARIANT = 'variant',
  COMBO = 'combo',
}

export class CreateProductDto {
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @IsOptional()
  @IsString()
  sku?: string;

  @IsOptional()
  @IsString()
  barcode?: string;

  @IsString()
  @IsNotEmpty()
  @Length(1, 255)
  name: string;

  @IsOptional()
  @IsString()
  nameEn?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsEnum(ProductType)
  @IsOptional()
  productType?: ProductType = ProductType.SIMPLE;

  @IsNumber()
  @Min(0)
  basePrice: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  cost?: number;

  @IsOptional()
  @IsString()
  unit?: string;

  @IsOptional()
  @IsBoolean()
  trackStock?: boolean;

  @IsOptional()
  @IsBoolean()
  allowModifiers?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}

export class UpdateProductDto {
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @IsOptional()
  @IsString()
  @Length(1, 255)
  name?: string;

  @IsOptional()
  @IsString()
  nameEn?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  basePrice?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  cost?: number;

  @IsOptional()
  @IsBoolean()
  trackStock?: boolean;

  @IsOptional()
  @IsBoolean()
  allowModifiers?: boolean;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}

export class CreateVariantDto {
  @IsString()
  @IsNotEmpty()
  @Length(1, 255)
  name: string;

  @IsNumber()
  @Min(0)
  price: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  cost?: number;

  @IsOptional()
  @IsString()
  sku?: string;
}

export class CreateUnitConversionDto {
  @IsString()
  @IsNotEmpty()
  @Length(1, 50)
  fromUnit: string;

  @IsString()
  @IsNotEmpty()
  @Length(1, 50)
  toUnit: string;

  @IsNumber()
  @Min(0.000001)
  conversionRate: number;
}

export class UploadProductImageDto {
  @IsString()
  @IsNotEmpty()
  @Length(3, 255)
  fileName: string;

  @IsBase64()
  dataBase64: string;

  @IsOptional()
  @IsString()
  mimeType?: string;
}
