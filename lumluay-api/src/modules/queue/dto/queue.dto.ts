import { IsString, IsOptional, IsNumber, IsUUID, Min, MaxLength } from 'class-validator';

export class CreateQueueEntryDto {
  @IsString()
  @MaxLength(255)
  name: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  phone?: string;

  @IsNumber()
  @Min(1)
  guestCount: number;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsUUID()
  memberId?: string;
}

export class UpdateQueueStatusDto {
  status: 'waiting' | 'called' | 'seated' | 'cancelled' | 'no_show';

  @IsOptional()
  @IsUUID()
  orderId?: string;

  @IsOptional()
  @IsNumber()
  estimatedWaitMinutes?: number;
}
