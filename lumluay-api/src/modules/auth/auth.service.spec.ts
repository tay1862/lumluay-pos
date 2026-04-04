import { UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';

describe('AuthService', () => {
  it('revokes all sessions when refresh token is reused/unknown', async () => {
    const mockDb: any = {
      query: {
        userSessions: {
          findFirst: jest.fn().mockResolvedValue(undefined),
        },
      },
    };

    const mockJwtService: any = {
      decode: jest.fn().mockReturnValue({ sub: 'user-1' }),
    };

    const mockConfigService: any = {
      get: jest.fn(),
    };

    const service = new AuthService(mockDb, mockJwtService, mockConfigService);
    const logoutAllSpy = jest
      .spyOn(service, 'logoutAll')
      .mockResolvedValue(undefined);

    await expect(
      service.refresh({ refreshToken: 'reused-token' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);

    expect(logoutAllSpy).toHaveBeenCalledWith('user-1');
  });
});
