import { PipeTransform, Injectable, ArgumentMetadata } from '@nestjs/common';
import { filterXSS } from 'xss';

/**
 * SanitizePipe — strips HTML/XSS from all string values recursively.
 *
 * Applied globally in main.ts via app.useGlobalPipes().
 * Works in conjunction with ValidationPipe (whitelist + forbidNonWhitelisted)
 * which already prevents extra fields and validates types.
 *
 * Security: Addresses OWASP A03 (Injection) and A07 (XSS).
 * Drizzle ORM uses parameterized queries → SQL injection is covered at the DB layer.
 */
@Injectable()
export class SanitizePipe implements PipeTransform {
  transform(value: unknown, _metadata: ArgumentMetadata): unknown {
    return this.sanitize(value);
  }

  private sanitize(value: unknown): unknown {
    if (typeof value === 'string') {
      return filterXSS(value.trim(), {
        whiteList: {},       // no HTML tags allowed
        stripIgnoreTag: true,
        stripIgnoreTagBody: ['script', 'style'],
      });
    }
    if (Array.isArray(value)) {
      return value.map((item) => this.sanitize(item));
    }
    if (value !== null && typeof value === 'object') {
      const sanitized: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
        sanitized[k] = this.sanitize(v);
      }
      return sanitized;
    }
    return value;
  }
}
