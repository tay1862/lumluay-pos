import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { OrdersController } from '@/modules/orders/orders.controller';
import { PaymentsController } from '@/modules/payments/payments.controller';
import { OrdersService } from '@/modules/orders/orders.service';
import { PaymentsService } from '@/modules/payments/payments.service';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';

describe('18.1.6 Order Flow (e2e)', () => {
  let app: NestFastifyApplication;

  const orderId = '11111111-1111-1111-1111-111111111111';
  const itemId = '22222222-2222-2222-2222-222222222222';

  const ordersServiceMock = {
    create: jest.fn().mockResolvedValue({ id: orderId, status: 'open' }),
    addItem: jest.fn().mockResolvedValue({ id: itemId }),
    sendToKitchen: jest.fn().mockResolvedValue({ success: true, sentCount: 1 }),
    findAll: jest.fn().mockResolvedValue([]),
    findOne: jest.fn().mockResolvedValue({ id: orderId }),
    updateItem: jest.fn().mockResolvedValue({}),
    removeItem: jest.fn().mockResolvedValue(undefined),
    confirm: jest.fn().mockResolvedValue({}),
    cancel: jest.fn().mockResolvedValue({}),
    applyDiscount: jest.fn().mockResolvedValue({}),
    hold: jest.fn().mockResolvedValue({}),
    resume: jest.fn().mockResolvedValue({}),
    voidOrder: jest.fn().mockResolvedValue({}),
    voidOrderItem: jest.fn().mockResolvedValue({}),
  };

  const paymentsServiceMock = {
    create: jest.fn().mockResolvedValue({ payment: { id: 'pay-1' } }),
    completeOrder: jest.fn().mockResolvedValue({ order: { id: orderId, status: 'completed' } }),
    findByOrder: jest.fn().mockResolvedValue([]),
    refundOrder: jest.fn().mockResolvedValue({}),
  };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [OrdersController, PaymentsController],
      providers: [
        { provide: OrdersService, useValue: ordersServiceMock },
        { provide: PaymentsService, useValue: paymentsServiceMock },
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
      req.user = { id: '33333333-3333-3333-3333-333333333333' };
      done();
    });
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('runs create -> add item -> send kitchen -> pay -> complete', async () => {
    await request(app.getHttpServer())
      .post('/orders')
      .send({ orderType: 'dine_in' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/orders/${orderId}/items`)
      .send({
        productId: '44444444-4444-4444-4444-444444444444',
        quantity: 1,
        unitPrice: 50,
      })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/orders/${orderId}/send-to-kitchen`)
      .send({ itemIds: [itemId] })
      .expect(200);

    await request(app.getHttpServer())
      .post(`/orders/${orderId}/payments`)
      .send({ amount: 50, method: 'cash' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/orders/${orderId}/complete`)
      .send({})
      .expect(201);

    expect(ordersServiceMock.create).toHaveBeenCalled();
    expect(ordersServiceMock.addItem).toHaveBeenCalled();
    expect(ordersServiceMock.sendToKitchen).toHaveBeenCalled();
    expect(paymentsServiceMock.create).toHaveBeenCalled();
    expect(paymentsServiceMock.completeOrder).toHaveBeenCalled();
  });
});
