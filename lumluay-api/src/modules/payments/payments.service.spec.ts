import { BadRequestException } from '@nestjs/common';
import { PaymentsService } from './payments.service';

describe('PaymentsService', () => {
  it('throws when paid amount is less than order total on complete', async () => {
    const mockDb: any = {
      query: {
        orders: {
          findFirst: jest.fn().mockResolvedValue({
            id: 'order-1',
            totalAmount: '200',
            status: 'open',
            customerId: null,
            extra: null,
          }),
        },
        payments: {
          findMany: jest.fn().mockResolvedValue([{ amount: '50' }]),
        },
      },
    };

    const service = new PaymentsService(
      mockDb,
      { toBase: jest.fn() } as any,
      { create: jest.fn() } as any,
      { findByCode: jest.fn(), incrementUsage: jest.fn() } as any,
    );

    await expect(
      service.completeOrder('tenant-1', 'order-1'),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
