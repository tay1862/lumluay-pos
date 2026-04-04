import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { AuthController } from '@/modules/auth/auth.controller';
import { AuthService } from '@/modules/auth/auth.service';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';

describe('18.1.7 Auth Flow (e2e)', () => {
  let app: NestFastifyApplication;

  const authServiceMock = {
    login: jest.fn().mockResolvedValue({ accessToken: 'a', refreshToken: 'r' }),
    loginWithPin: jest
      .fn()
      .mockResolvedValue({ accessToken: 'a2', refreshToken: 'r2' }),
    refresh: jest.fn().mockResolvedValue({ accessToken: 'a3', refreshToken: 'r3' }),
    logout: jest.fn().mockResolvedValue(undefined),
    logoutAll: jest.fn().mockResolvedValue(undefined),
  };

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [{ provide: AuthService, useValue: authServiceMock }],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = moduleRef.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
    );
    app.getHttpAdapter().getInstance().addHook('onRequest', (req: any, _reply: any, done: () => void) => {
      req.tenantId = 'tenant-e2e';
      req.user = { id: '11111111-1111-1111-1111-111111111111', sessionId: 'session-1' };
      done();
    });
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('runs login -> refresh -> pin -> logout', async () => {
    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ username: 'cashier', password: 'pass1234' })
      .expect(200);

    await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: 'refresh-token' })
      .expect(200);

    await request(app.getHttpServer())
      .post('/auth/login/pin')
      .send({ pin: '1234' })
      .expect(200);

    await request(app.getHttpServer()).post('/auth/logout').send({}).expect(204);

    expect(authServiceMock.login).toHaveBeenCalled();
    expect(authServiceMock.refresh).toHaveBeenCalled();
    expect(authServiceMock.loginWithPin).toHaveBeenCalled();
    expect(authServiceMock.logout).toHaveBeenCalled();
  });
});
