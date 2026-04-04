import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { AuthController } from '@/modules/auth/auth.controller';
import { OrdersController } from '@/modules/orders/orders.controller';
import { PaymentsController } from '@/modules/payments/payments.controller';
import { AuthService } from '@/modules/auth/auth.service';
import { OrdersService } from '@/modules/orders/orders.service';
import { PaymentsService } from '@/modules/payments/payments.service';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';

describe('18.1.9 Critical API Endpoints (e2e)', () => {
  let app: NestFastifyApplication;

  const orderId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [AuthController, OrdersController, PaymentsController],
      providers: [
        {
          provide: AuthService,
          useValue: {
            login: jest.fn().mockResolvedValue({ accessToken: 'x', refreshToken: 'y' }),
            loginWithPin: jest.fn().mockResolvedValue({ accessToken: 'x2', refreshToken: 'y2' }),
            refresh: jest.fn().mockResolvedValue({ accessToken: 'x3', refreshToken: 'y3' }),
            logout: jest.fn().mockResolvedValue(undefined),
            logoutAll: jest.fn().mockResolvedValue(undefined),
          },
        },
        {
          provide: OrdersService,
          useValue: {
            create: jest.fn().mockResolvedValue({ id: orderId }),
            findAll: jest.fn().mockResolvedValue([]),
            findOne: jest.fn().mockResolvedValue({ id: orderId }),
            addItem: jest.fn().mockResolvedValue({}),
            updateItem: jest.fn().mockResolvedValue({}),
            removeItem: jest.fn().mockResolvedValue({}),
            confirm: jest.fn().mockResolvedValue({}),
            cancel: jest.fn().mockResolvedValue({}),
            applyDiscount: jest.fn().mockResolvedValue({}),
            hold: jest.fn().mockResolvedValue({}),
            resume: jest.fn().mockResolvedValue({}),
            voidOrder: jest.fn().mockResolvedValue({}),
            voidOrderItem: jest.fn().mockResolvedValue({}),
            sendToKitchen: jest.fn().mockResolvedValue({}),
          },
        },
        {
          provide: PaymentsService,
          useValue: {
            findByOrder: jest.fn().mockResolvedValue([]),
            create: jest.fn().mockResolvedValue({ payment: { id: 'pay-1' } }),
            completeOrder: jest.fn().mockResolvedValue({ order: { id: orderId } }),
            refundOrder: jest.fn().mockResolvedValue({}),
          },
        },
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
    app.getHttpAdapter().getInstance().addHook('onRequest', (req: any, _reply: any, done: () => void) => {
      req.tenantId = 'tenant-e2e';
      req.user = { id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', sessionId: 'session-e2e' };
      done();
    });
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('hits critical auth/orders/payments endpoints', async () => {
    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'owner', password: 'password' })
      .expect(200);

    await request(app.getHttpServer())
      .post('/orders')
      .send({ orderType: 'dine_in' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/orders/${orderId}/payments`)
      .send({ amount: 100, method: 'cash' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/orders/${orderId}/complete`)
      .send({})
      .expect(201);
  });
});
