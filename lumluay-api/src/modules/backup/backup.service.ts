import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { execFile } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs';
import * as path from 'path';
import * as zlib from 'zlib';

const execFileAsync = promisify(execFile);

@Injectable()
export class BackupService {
  private readonly logger = new Logger(BackupService.name);
  private readonly backupDir = process.env.BACKUP_DIR ?? '/tmp/lumluay-backups';

  /** Runs daily at 03:00 UTC */
  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async runDailyBackup() {
    this.logger.log('Starting daily database backup...');
    try {
      const filePath = await this.createBackup();
      this.logger.log(`Backup completed: ${filePath}`);
      await this.pruneOldBackups(7);
    } catch (err) {
      this.logger.error('Backup failed', err instanceof Error ? err.message : String(err));
    }
  }

  async createBackup(): Promise<string> {
    if (!fs.existsSync(this.backupDir)) {
      fs.mkdirSync(this.backupDir, { recursive: true });
    }

    const dateStr = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    const dumpFile = path.join(this.backupDir, `lumluay-${dateStr}.sql`);
    const gzFile = `${dumpFile}.gz`;

    const dbUrl = process.env.DATABASE_URL;
    if (!dbUrl) throw new Error('DATABASE_URL is not set');

    // Use execFile with explicit args to prevent command injection
    await execFileAsync('pg_dump', [dbUrl, '-F', 'c', '-f', dumpFile]);

    await new Promise<void>((resolve, reject) => {
      const readStream = fs.createReadStream(dumpFile);
      const writeStream = fs.createWriteStream(gzFile);
      const gzip = zlib.createGzip();
      readStream
        .pipe(gzip)
        .pipe(writeStream)
        .on('finish', resolve)
        .on('error', reject);
    });

    fs.unlinkSync(dumpFile);
    return gzFile;
  }

  async pruneOldBackups(keepDays: number) {
    if (!fs.existsSync(this.backupDir)) return;

    const cutoff = Date.now() - keepDays * 24 * 60 * 60 * 1000;
    const files = fs.readdirSync(this.backupDir).filter((f) => f.endsWith('.gz'));

    for (const file of files) {
      const filePath = path.join(this.backupDir, file);
      const stat = fs.statSync(filePath);
      if (stat.mtimeMs < cutoff) {
        fs.unlinkSync(filePath);
        this.logger.log(`Pruned old backup: ${file}`);
      }
    }
  }

  listBackups(): { name: string; size: number; createdAt: Date }[] {
    if (!fs.existsSync(this.backupDir)) return [];

    return fs
      .readdirSync(this.backupDir)
      .filter((f) => f.endsWith('.gz'))
      .map((file) => {
        const stat = fs.statSync(path.join(this.backupDir, file));
        return { name: file, size: stat.size, createdAt: stat.mtime };
      })
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }
}
