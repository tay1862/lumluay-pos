import { IsString, IsOptional, IsArray, ValidateNested, IsUUID } from 'class-validator';
import { Type } from 'class-transformer';

export class SyncOperationDto {
  @IsString()
  operation: 'create' | 'update' | 'delete';

  @IsString()
  entityType: string;

  @IsOptional()
  @IsUUID()
  entityId?: string;

  payload: Record<string, unknown>;

  @IsOptional()
  @IsString()
  checksum?: string;

  @IsString()
  clientTimestamp: string;
}

export class PushSyncDto {
  @IsString()
  deviceId: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncOperationDto)
  operations: SyncOperationDto[];
}

export class PullSyncDto {
  @IsString()
  deviceId: string;

  @IsOptional()
  @IsString()
  since?: string;
}
