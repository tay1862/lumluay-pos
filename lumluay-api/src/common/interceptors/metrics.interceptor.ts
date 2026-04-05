import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { httpRequestsTotal, httpRequestDuration } from '@/modules/health/metrics.controller';

@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest();
    const method = req.method ?? 'GET';
    const route = req.routeOptions?.url ?? req.url ?? 'unknown';
    const start = process.hrtime.bigint();

    return next.handle().pipe(
      tap({
        next: () => {
          const res = context.switchToHttp().getResponse();
          const statusCode = String(res.statusCode ?? 200);
          const durationSec =
            Number(process.hrtime.bigint() - start) / 1e9;
          httpRequestsTotal.inc({ method, route, status_code: statusCode });
          httpRequestDuration.observe(
            { method, route, status_code: statusCode },
            durationSec,
          );
        },
        error: (err) => {
          const statusCode = String(err?.status ?? 500);
          const durationSec =
            Number(process.hrtime.bigint() - start) / 1e9;
          httpRequestsTotal.inc({ method, route, status_code: statusCode });
          httpRequestDuration.observe(
            { method, route, status_code: statusCode },
            durationSec,
          );
        },
      }),
    );
  }
}
