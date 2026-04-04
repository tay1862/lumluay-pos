import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { FastifyRequest } from 'fastify';
import { Observable } from 'rxjs';
import { switchMap, finalize } from 'rxjs/operators';
import { sql } from 'drizzle-orm';
import { InjectDrizzle } from '../../database/database.module';
import type { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import type * as schema from '../../database/schema';

/**
 * TenantRlsInterceptor
 *
 * Sets the PostgreSQL session parameter `app.tenant_id` to the current tenant's
 * UUID before any database query is executed in the request lifecycle.
 *
 * Combined with the RLS policies in migration 20260402_004_rls_policies.sql,
 * this ensures every query is automatically filtered to the current tenant — even
 * if service code accidentally omits a `tenantId` WHERE clause.
 *
 * Registration: Apply globally in AppModule or on specific controllers.
 *   app.useGlobalInterceptors(new TenantRlsInterceptor(db));
 */
@Injectable()
export class TenantRlsInterceptor implements NestInterceptor {
  constructor(
    @InjectDrizzle()
    private readonly db: PostgresJsDatabase<typeof schema>,
  ) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context
      .switchToHttp()
      .getRequest<FastifyRequest & { tenantId?: string }>();

    const tenantId = req.tenantId;

    if (!tenantId) {
      // No tenant context (e.g. health-check, public routes) — skip
      return next.handle();
    }

    // set_config(key, value, is_local):
    //   is_local = false → session-scoped (lasts until connection is returned to pool)
    //   is_local = true  → transaction-scoped (preferred, but requires explicit BEGIN)
    //
    // We use false here because Drizzle does not wrap every query in an explicit
    // transaction.  The connection pool (postgres-js) assigns one connection per
    // concurrent request, so session-scoped settings are safe in practice.
    return new Observable((subscriber) => {
      this.db
        .execute(sql`SELECT set_config('app.tenant_id', ${tenantId}, false)`)
        .then(() => {
          next
            .handle()
            .pipe(
              switchMap((value) => [value]),
              finalize(() => {
                // Best-effort reset: prevents the tenant_id from leaking to the
                // next request that reuses this pooled connection.
                this.db
                  .execute(sql`RESET app.tenant_id`)
                  .catch(() => undefined);
              }),
            )
            .subscribe({
              next: (v) => subscriber.next(v),
              error: (e) => subscriber.error(e),
              complete: () => subscriber.complete(),
            });
        })
        .catch((err) => subscriber.error(err));
    });
  }
}
