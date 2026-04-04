import {
  Injectable,
  NestMiddleware,
  BadRequestException,
} from '@nestjs/common';
import { FastifyRequest, FastifyReply } from 'fastify';

// UUID v4 regex — used to validate the tenant ID extracted from subdomain or header.
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@Injectable()
export class TenantMiddleware implements NestMiddleware {
  use(
    req: FastifyRequest & { tenantId?: string },
    _res: FastifyReply,
    next: () => void,
  ) {
    const tenantId =
      (req.headers['x-tenant-id'] as string | undefined) ??
      this.extractFromHost(req.hostname);

    if (!tenantId) {
      throw new BadRequestException('Tenant identifier is required');
    }

    // The x-tenant-id header (or subdomain) must be a valid UUID when it
    // looks like one.  Non-UUID slugs (e.g. 'acme') are allowed through and
    // resolved to a real UUID by downstream services via the tenants table.
    if (tenantId.includes('-') && !UUID_RE.test(tenantId)) {
      throw new BadRequestException('Invalid tenant identifier format');
    }

    req.tenantId = tenantId;
    next();
  }

  private extractFromHost(hostname: string): string | undefined {
    // e.g. acme.lumluay.com → acme
    const parts = hostname.split('.');
    if (parts.length >= 3) {
      return parts[0];
    }
    return undefined;
  }
}
