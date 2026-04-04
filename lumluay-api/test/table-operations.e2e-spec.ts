import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { TablesController } from '@/modules/tables/tables.controller';
import { TablesService } from '@/modules/tables/tables.service';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';

describe('18.1.8 Table Operations (e2e)', () => {
  let app: NestFastifyApplication;

  const tableId = '55555555-5555-5555-5555-555555555555';
  const targetTableId = '66666666-6666-6666-6666-666666666666';

  const tablesServiceMock = {
    moveTable: jest.fn().mockResolvedValue({ success: true }),
    mergeTables: jest.fn().mockResolvedValue({ success: true }),
    splitTable: jest.fn().mockResolvedValue({ success: true }),
    findAll: jest.fn().mockResolvedValue([]),
    findZones: jest.fn().mockResolvedValue([]),
    createZone: jest.fn().mockResolvedValue({}),
    updateZone: jest.fn().mockResolvedValue({}),
    deleteZone: jest.fn().mockResolvedValue({}),
    findOne: jest.fn().mockResolvedValue({}),
    create: jest.fn().mockResolvedValue({}),
    update: jest.fn().mockResolvedValue({}),
    setStatus: jest.fn().mockResolvedValue({}),
    generateTableQrCode: jest.fn().mockResolvedValue({}),
  };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [TablesController],
      providers: [{ provide: TablesService, useValue: tablesServiceMock }],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = moduleRef.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
    );
    app.getHttpAdapter().getInstance().addHook('onRequest', (req: any, _reply: any, done: () => void) => {
      req.tenantId = 'tenant-e2e';
      done();
    });
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('runs move, merge, split endpoints', async () => {
    await request(app.getHttpServer())
      .post(`/tables/${tableId}/move`)
      .send({ targetTableId })
      .expect(201);

    await request(app.getHttpServer())
      .post('/tables/merge')
      .send({ targetTableId, mergeTableIds: [tableId] })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/tables/${tableId}/split`)
      .send({ targetTableId, itemIds: ['77777777-7777-7777-7777-777777777777'] })
      .expect(201);

    expect(tablesServiceMock.moveTable).toHaveBeenCalled();
    expect(tablesServiceMock.mergeTables).toHaveBeenCalled();
    expect(tablesServiceMock.splitTable).toHaveBeenCalled();
  });
});
