import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';
import { Roles } from '@/common/decorators/roles.decorator';
import { BackupService } from './backup.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('super_admin')
@Controller('backup')
export class BackupController {
  constructor(private readonly backupService: BackupService) {}

  @Get()
  listBackups() {
    return this.backupService.listBackups();
  }

  @Post()
  async triggerBackup() {
    const filePath = await this.backupService.createBackup();
    return { success: true, filePath };
  }
}
