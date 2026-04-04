import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

/**
 * TrainingInterceptor
 * ---------------------
 * When the request contains `X-Training-Mode: true` header (or the tenant
 * has training_mode enabled), this interceptor tags all response data with
 * `_training: true` at the top level so the client can display a visual
 * indicator and know that no real data was written.
 *
 * NOTE: Actual training-mode data isolation (routing writes to a separate
 * staging schema) must be enforced at the service layer. This interceptor
 * only annotates the response.
 */
@Injectable()
export class TrainingInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest<{
      headers: Record<string, string>;
    }>();

    const isTraining =
      request.headers['x-training-mode'] === 'true' ||
      request.headers['x-training-mode'] === '1';

    if (!isTraining) {
      return next.handle();
    }

    return next.handle().pipe(
      map((data) => {
        if (data && typeof data === 'object') {
          return { ...data, _training: true };
        }
        return data;
      }),
    );
  }
}
