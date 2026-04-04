import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEmail,
  IsEnum,
  IsBoolean,
  IsInt,
  Min,
  Max,
  Length,
} from 'class-validator';

export enum UserRole {
  OWNER = 'owner',
  MANAGER = 'manager',
  CASHIER = 'cashier',
  WAITER = 'waiter',
  KITCHEN = 'kitchen',
}

export class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  @Length(3, 100)
  username: string;

  @IsString()
  @IsNotEmpty()
  @Length(8, 100)
  password: string;

  @IsString()
  @IsNotEmpty()
  @Length(1, 255)
  displayName: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsEnum(UserRole)
  role: UserRole;

  @IsOptional()
  @IsString()
  @Length(4, 8)
  pinCode?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(480)
  autoLockMinutes?: number;
}

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  @Length(1, 255)
  displayName?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(480)
  autoLockMinutes?: number;

  @IsOptional()
  @IsString()
  avatarUrl?: string;
}

export class SetPinDto {
  @IsString()
  @IsNotEmpty()
  @Length(4, 8)
  pin: string;
}
