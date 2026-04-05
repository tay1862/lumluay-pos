import { Controller, Get, Res } from '@nestjs/common';
import { FastifyReply } from 'fastify';
import * as client from 'prom-client';

// Collect default Node.js metrics (event loop, heap, GC, etc.)
client.collectDefaultMetrics();

// ─── Custom metrics ──────────────────────────────────────────────────────────

export const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'] as const,
});

export const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'] as const,
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5],
});

// ─── Controller ──────────────────────────────────────────────────────────────

@Controller('health')
export class MetricsController {
  @Get('metrics')
  async metrics(@Res() reply: FastifyReply) {
    const metricsOutput = await client.register.metrics();
    reply.header('Content-Type', client.register.contentType).send(metricsOutput);
  }
}
