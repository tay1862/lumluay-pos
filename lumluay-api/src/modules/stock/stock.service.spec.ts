import { StockService } from './stock.service';

describe('StockService', () => {
  it('creates stock level and movement when no current level exists', async () => {
    const movement = { id: 'mv-1', quantity: '5' };

    const mockDb: any = {
      query: {
        stockLevels: {
          findFirst: jest.fn().mockResolvedValue(null),
        },
      },
      insert: jest
        .fn()
        .mockReturnValueOnce({ values: jest.fn().mockResolvedValue(undefined) })
        .mockReturnValueOnce({
          values: jest.fn().mockReturnValue({
            returning: jest.fn().mockResolvedValue([movement]),
          }),
        }),
    };

    const service = new StockService(mockDb);

    const result = await service.adjust('tenant-1', 'user-1', {
      productId: 'product-1',
      quantity: 5,
      type: 'purchase',
    });

    expect(result).toEqual(movement);
    expect(mockDb.insert).toHaveBeenCalledTimes(2);
  });
});
