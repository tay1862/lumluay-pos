import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import * as request from 'supertest';
import { CouponsController } from '@/modules/coupons/coupons.controller';
import { CouponsService } from '@/modules/coupons/coupons.service';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';

describe('CouponsService', () => {
  let app: INestApplication;

  const mockCoupon = {
    id: 'coupon-1',
    code: 'SUMMER20',
    discountType: 'percentage',
    discountValue: 20,
    minOrderAmount: 100,
    maxUsage: 50,
    usageCount: 10,
    isActive: true,
    expiresAt: new Date(Date.now() + 86400000).toISOString(),
  };

  const mockCouponsService = {
    findAll: jest.fn().mockResolvedValue([mockCoupon]),
    validate: jest.fn().mockResolvedValue(mockCoupon),
    create: jest.fn().mockResolvedValue(mockCoupon),
    update: jest.fn().mockResolvedValue({ ...mockCoupon, discountValue: 25 }),
    remove: jest.fn().mockResolvedValue({ deleted: true }),
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      controllers: [CouponsController],
      providers: [
        { provide: CouponsService, useValue: mockCouponsService },
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
      req.user = { sub: 'user-1', tenantId: 'tenant-test', role: 'manager' };
      done();
    });

    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /coupons — should return all coupons', async () => {
    const res = await request(app.getHttpServer()).get('/coupons').expect(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].code).toBe('SUMMER20');
    expect(mockCouponsService.findAll).toHaveBeenCalled();
  });

  it('POST /coupons/validate — should validate a coupon code', async () => {
    const res = await request(app.getHttpServer())
      .post('/coupons/validate')
      .send({ code: 'SUMMER20' })
      .expect(200);
    expect(res.body.discountType).toBe('percentage');
    expect(mockCouponsService.validate).toHaveBeenCalled();
  });

  it('POST /coupons — should create coupon', async () => {
    await request(app.getHttpServer())
      .post('/coupons')
      .send({
        code: 'SUMMER20',
        discountType: 'percentage',
        discountValue: 20,
      })
      .expect(201);
    expect(mockCouponsService.create).toHaveBeenCalled();
  });
});
