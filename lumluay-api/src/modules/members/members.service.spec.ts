import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import * as request from 'supertest';
import { MembersController } from '@/modules/members/members.controller';
import { MembersService } from '@/modules/members/members.service';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';

describe('MembersService', () => {
  let app: INestApplication;

  const memberId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

  const mockMember = {
    id: memberId,
    name: 'John Doe',
    phone: '0812345678',
    points: 150,
    totalSpent: 5000,
    createdAt: new Date().toISOString(),
  };

  const mockMembersService = {
    findAll: jest.fn().mockResolvedValue([mockMember]),
    findByPhone: jest.fn().mockResolvedValue(mockMember),
    create: jest.fn().mockResolvedValue(mockMember),
    update: jest.fn().mockResolvedValue({ ...mockMember, name: 'Jane Doe' }),
    getOrderHistory: jest.fn().mockResolvedValue([
      { id: 'order-1', total: 500, createdAt: new Date().toISOString() },
    ]),
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      controllers: [MembersController],
      providers: [
        { provide: MembersService, useValue: mockMembersService },
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

  it('GET /members — should return all members', async () => {
    const res = await request(app.getHttpServer()).get('/members').expect(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].name).toBe('John Doe');
    expect(mockMembersService.findAll).toHaveBeenCalled();
  });

  it('GET /members?search=phone — should find by search', async () => {
    const res = await request(app.getHttpServer())
      .get('/members?search=0812345678')
      .expect(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].points).toBe(150);
    expect(mockMembersService.findAll).toHaveBeenCalledWith('tenant-test', '0812345678');
  });

  it('POST /members — should create a member', async () => {
    await request(app.getHttpServer())
      .post('/members')
      .send({ name: 'John Doe', phone: '0812345678' })
      .expect(201);
    expect(mockMembersService.create).toHaveBeenCalled();
  });

  it('GET /members/:id/orders — should return order history', async () => {
    const res = await request(app.getHttpServer())
      .get(`/members/${memberId}/orders`)
      .expect(200);
    expect(res.body).toHaveLength(1);
    expect(mockMembersService.getOrderHistory).toHaveBeenCalledWith('tenant-test', memberId);
  });
});
