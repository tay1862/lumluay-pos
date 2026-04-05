import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import * as request from 'supertest';
import { NotificationsController } from '@/modules/notifications/notifications.controller';
import { NotificationsService } from '@/modules/notifications/notifications.service';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';

describe('NotificationsService', () => {
  let app: INestApplication;

  const notifId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

  const mockNotificationsService = {
    findForUser: jest.fn().mockResolvedValue([
      {
        id: notifId,
        title: 'New Order',
        body: 'Order #1001 received',
        isRead: false,
        createdAt: new Date().toISOString(),
      },
      {
        id: 'notif-2',
        title: 'Stock Alert',
        body: 'Low stock on Pad Thai',
        isRead: true,
        createdAt: new Date().toISOString(),
      },
    ]),
    getUnreadCount: jest.fn().mockResolvedValue(1),
    markRead: jest.fn().mockResolvedValue({ id: 'notif-1', isRead: true }),
    markAllRead: jest.fn().mockResolvedValue({ updated: 1 }),
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      controllers: [NotificationsController],
      providers: [
        { provide: NotificationsService, useValue: mockNotificationsService },
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
      req.user = { id: 'user-1', tenantId: 'tenant-test', role: 'manager', username: 'test' };
      done();
    });

    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /notifications — should return user notifications', async () => {
    const res = await request(app.getHttpServer())
      .get('/notifications')
      .expect(200);
    expect(res.body).toHaveLength(2);
    expect(mockNotificationsService.findForUser).toHaveBeenCalled();
  });

  it('GET /notifications/unread-count — should return count', async () => {
    const res = await request(app.getHttpServer())
      .get('/notifications/unread-count')
      .expect(200);
    expect(res.body).toEqual(1);
    expect(mockNotificationsService.getUnreadCount).toHaveBeenCalled();
  });

  it('PATCH /notifications/:id/read — should mark as read', async () => {
    await request(app.getHttpServer())
      .patch(`/notifications/${notifId}/read`)
      .expect(200);
    expect(mockNotificationsService.markRead).toHaveBeenCalledWith('tenant-test', 'user-1', notifId);
  });

  it('PATCH /notifications/read-all — should mark all read', async () => {
    await request(app.getHttpServer())
      .patch('/notifications/read-all')
      .expect(200);
    expect(mockNotificationsService.markAllRead).toHaveBeenCalled();
  });
});
