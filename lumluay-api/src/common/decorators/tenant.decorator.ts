import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { FastifyRequest } from 'fastify';

export const TenantId = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): string => {
    const request = ctx.switchToHttp().getRequest<
      FastifyRequest & {
        tenantId?: string;
        user?: { tenantId?: string };
      }
    >();

    return request.tenantId ?? request.user?.tenantId ?? '';
  },
);
