import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import * as request from 'supertest';
import { ShiftsController } from '@/modules/shifts/shifts.controller';
import { ShiftsService } from '@/modules/shifts/shifts.service';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';

describe('ShiftsService', () => {
  let app: INestApplication;

  const mockShift = {
    id: 'shift-1',
    userId: 'user-1',
    openedAt: new Date().toISOString(),
    closedAt: null,
    openingCash: 1000,
    closingCash: null,
    totalSales: 0,
  };

  const mockShiftsService = {
    getCurrent: jest.fn().mockResolvedValue(mockShift),
    open: jest.fn().mockResolvedValue(mockShift),
    close: jest.fn().mockResolvedValue({
      ...mockShift,
      closedAt: new Date().toISOString(),
      closingCash: 5000,
      totalSales: 4000,
    }),
    findAll: jest.fn().mockResolvedValue([mockShift]),
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      controllers: [ShiftsController],
      providers: [
        { provide: ShiftsService, useValue: mockShiftsService },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = moduleRef.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
    );

    const instance = app.getHttpAdapter().getInstance();
    instance.addHook('onRequest', (req: any, _reply: any, done: () => void) => {
      req.tenantId = 'tenant-test';
      req.user = { sub: 'user-1', tenantId: 'tenant-test', role: 'cashier' };
      done();
    });

    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /shifts/current — should return current shift', async () => {
    const res = await request(app.getHttpServer())
      .get('/shifts/current')
      .expect(200);
    expect(res.body.openingCash).toBe(1000);
    expect(mockShiftsService.getCurrent).toHaveBeenCalled();
  });

  it('POST /shifts/open — should open a shift', async () => {
    await request(app.getHttpServer())
      .post('/shifts/open')
      .send({ openingCash: 1000 })
      .expect(201);
    expect(mockShiftsService.open).toHaveBeenCalled();
  });

  it('POST /shifts/close — should close a shift', async () => {
    const res = await request(app.getHttpServer())
      .post('/shifts/close')
      .send({ closingCash: 5000 })
      .expect(201);
    expect(res.body.totalSales).toBe(4000);
    expect(mockShiftsService.close).toHaveBeenCalled();
  });

  it('GET /shifts — should list all shifts', async () => {
    const res = await request(app.getHttpServer())
      .get('/shifts')
      .expect(200);
    expect(res.body).toHaveLength(1);
    expect(mockShiftsService.findAll).toHaveBeenCalled();
  });
});
