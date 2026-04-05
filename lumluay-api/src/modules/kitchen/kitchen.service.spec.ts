import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import * as request from 'supertest';
import { KitchenController } from '@/modules/kitchen/kitchen.controller';
import { KitchenService } from '@/modules/kitchen/kitchen.service';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';

describe('KitchenService', () => {
  let app: INestApplication;

  const ticketId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

  const mockKitchenService = {
    findPending: jest.fn().mockResolvedValue([
      {
        id: ticketId,
        orderId: 'order-1',
        orderNumber: '#1001',
        tableName: 'A1',
        items: [{ name: 'Pad Thai', qty: 2, notes: null }],
        status: 'pending',
        createdAt: new Date().toISOString(),
      },
    ]),
    startPreparing: jest.fn().mockResolvedValue({ id: ticketId, status: 'preparing' }),
    markReady: jest.fn().mockResolvedValue({ id: ticketId, status: 'ready' }),
    markServed: jest.fn().mockResolvedValue({ id: ticketId, status: 'served' }),
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      controllers: [KitchenController],
      providers: [
        { provide: KitchenService, useValue: mockKitchenService },
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
      req.user = { sub: 'user-1', tenantId: 'tenant-test', role: 'kitchen' };
      done();
    });

    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /kitchen/tickets — should return pending tickets', async () => {
    const res = await request(app.getHttpServer()).get('/kitchen/tickets').expect(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].orderNumber).toBe('#1001');
    expect(mockKitchenService.findPending).toHaveBeenCalled();
  });

  it('POST /kitchen/tickets/:id/preparing — should start preparing', async () => {
    await request(app.getHttpServer())
      .post(`/kitchen/tickets/${ticketId}/preparing`)
      .expect(201);
    expect(mockKitchenService.startPreparing).toHaveBeenCalledWith('tenant-test', ticketId);
  });

  it('POST /kitchen/tickets/:id/ready — should mark as ready', async () => {
    await request(app.getHttpServer())
      .post(`/kitchen/tickets/${ticketId}/ready`)
      .expect(201);
    expect(mockKitchenService.markReady).toHaveBeenCalledWith('tenant-test', ticketId);
  });

  it('POST /kitchen/tickets/:id/served — should mark as served', async () => {
    await request(app.getHttpServer())
      .post(`/kitchen/tickets/${ticketId}/served`)
      .expect(201);
    expect(mockKitchenService.markServed).toHaveBeenCalledWith('tenant-test', ticketId);
  });
});
