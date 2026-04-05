import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import * as request from 'supertest';
import { TablesController } from '@/modules/tables/tables.controller';
import { TablesService } from '@/modules/tables/tables.service';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';
import { RolesGuard } from '@/common/guards/roles.guard';

describe('TablesService', () => {
  let app: INestApplication;

  const tableId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

  const mockTable = {
    id: tableId,
    name: 'A1',
    zoneId: 'zone-1',
    seats: 4,
    status: 'available',
  };

  const mockZone = {
    id: 'zone-1',
    name: 'Indoor',
    tables: [mockTable],
  };

  const mockTablesService = {
    findAll: jest.fn().mockResolvedValue([mockTable]),
    findZones: jest.fn().mockResolvedValue([mockZone]),
    create: jest.fn().mockResolvedValue(mockTable),
    update: jest.fn().mockResolvedValue({ ...mockTable, name: 'A2' }),
    remove: jest.fn().mockResolvedValue({ deleted: true }),
    setStatus: jest.fn().mockResolvedValue({ ...mockTable, status: 'occupied' }),
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      controllers: [TablesController],
      providers: [
        { provide: TablesService, useValue: mockTablesService },
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

  it('GET /tables — should return all tables', async () => {
    const res = await request(app.getHttpServer()).get('/tables').expect(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].name).toBe('A1');
    expect(mockTablesService.findAll).toHaveBeenCalled();
  });

  it('GET /tables/zones — should return zones with tables', async () => {
    const res = await request(app.getHttpServer())
      .get('/tables/zones')
      .expect(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].name).toBe('Indoor');
    expect(mockTablesService.findZones).toHaveBeenCalled();
  });

  it('POST /tables — should create a table', async () => {
    await request(app.getHttpServer())
      .post('/tables')
      .send({ name: 'A1', zoneId: 'zone-1', seats: 4 })
      .expect(201);
    expect(mockTablesService.create).toHaveBeenCalled();
  });

  it('PATCH /tables/:id/status — should update table status', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/tables/${tableId}/status`)
      .send({ status: 'occupied' })
      .expect(200);
    expect(res.body.status).toBe('occupied');
    expect(mockTablesService.setStatus).toHaveBeenCalledWith('tenant-test', tableId, 'occupied');
  });
});
