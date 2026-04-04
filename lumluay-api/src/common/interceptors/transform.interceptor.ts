import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  meta?: Record<string, unknown>;
  timestamp: string;
}

@Injectable()
export class TransformInterceptor<T>
  implements NestInterceptor<T, ApiResponse<T>>
{
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map((data) => {
        // Services may return { data, meta } for paginated results.
        const isPaginated =
          data !== null &&
          typeof data === 'object' &&
          'data' in data &&
          'meta' in data;

        return {
          success: true,
          data: isPaginated ? (data as { data: T }).data : (data as T),
          ...(isPaginated ? { meta: (data as { meta: Record<string, unknown> }).meta } : {}),
          timestamp: new Date().toISOString(),
        };
      }),
    );
  }
}
