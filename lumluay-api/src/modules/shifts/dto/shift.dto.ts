import { IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class OpenShiftDto {
  @IsNumber()
  @Min(0)
  openingCash: number;

  @IsOptional()
  @IsString()
  note?: string;
}

export class CloseShiftDto {
  @IsNumber()
  @Min(0)
  closingCash: number;

  @IsOptional()
  @IsString()
  note?: string;
}
