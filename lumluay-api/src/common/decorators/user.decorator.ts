import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { FastifyRequest } from 'fastify';

export interface AuthUser {
  id: string;
  tenantId: string;
  role: string;
  username: string;
}

export const CurrentUser = createParamDecorator(
  (data: string | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest<FastifyRequest>();
    const user = (request as FastifyRequest & { user?: Record<string, unknown> })
      .user;
    return data ? user?.[data] : user;
  },
);
