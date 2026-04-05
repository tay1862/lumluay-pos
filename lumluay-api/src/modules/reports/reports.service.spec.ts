import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import * as request from 'supertest';
import { ReportsController } from '@/modules/reports/reports.controller';
import { ReportsService } from '@/modules/reports/reports.service';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';

describe('ReportsService', () => {
  let app: INestApplication;

  const mockReportsService = {
    getSummary: jest.fn().mockResolvedValue({
      totalOrders: 150,
      totalRevenue: 75000,
      averageOrderValue: 500,
      period: { from: '2026-04-01', to: '2026-04-05' },
    }),
    getDailyBreakdown: jest.fn().mockResolvedValue([
      { date: '2026-04-01', orders: 30, revenue: 15000 },
      { date: '2026-04-02', orders: 35, revenue: 17000 },
    ]),
    getTopProducts: jest.fn().mockResolvedValue([
      { productId: 'p1', name: 'Pad Thai', totalQty: 80, totalRevenue: 12000 },
      { productId: 'p2', name: 'Green Curry', totalQty: 60, totalRevenue: 10800 },
    ]),
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      controllers: [ReportsController],
      providers: [
        { provide: ReportsService, useValue: mockReportsService },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = moduleRef.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
    );

    const instance = app.getHttpAdapter().getInstance();
    instance.addHook('onRequest', (req: any, _reply: any, done: () => void) => {
      req.tenantId = 'tenant-test';
      req.user = { sub: 'user-1', tenantId: 'tenant-test', role: 'owner' };
      done();
    });

    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /reports/summary — should return sales summary', async () => {
    const res = await request(app.getHttpServer())
      .get('/reports/summary?from=2026-04-01&to=2026-04-05')
      .expect(200);
    expect(res.body.totalOrders).toBe(150);
    expect(res.body.totalRevenue).toBe(75000);
    expect(mockReportsService.getSummary).toHaveBeenCalled();
  });

  it('GET /reports/daily — should return daily breakdown', async () => {
    const res = await request(app.getHttpServer())
      .get('/reports/daily?from=2026-04-01&to=2026-04-05')
      .expect(200);
    expect(res.body).toHaveLength(2);
    expect(res.body[0].date).toBe('2026-04-01');
    expect(mockReportsService.getDailyBreakdown).toHaveBeenCalled();
  });

  it('GET /reports/top-products — should return top products', async () => {
    const res = await request(app.getHttpServer())
      .get('/reports/top-products?from=2026-04-01&to=2026-04-05')
      .expect(200);
    expect(res.body).toHaveLength(2);
    expect(res.body[0].name).toBe('Pad Thai');
    expect(mockReportsService.getTopProducts).toHaveBeenCalled();
  });
});
