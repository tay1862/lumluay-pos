import { OrderCalculationService } from './order-calculation.service';

describe('OrderCalculationService', () => {
  it('recalculates totals with service charge and exclusive tax', async () => {
    const whereMock = jest.fn().mockResolvedValue(undefined);
    const setMock = jest.fn().mockReturnValue({ where: whereMock });

    const mockDb: any = {
      query: {
        orders: {
          findFirst: jest.fn().mockResolvedValue({
            id: 'order-1',
            discountAmount: '10',
          }),
        },
        storeSettings: {
          findFirst: jest.fn().mockResolvedValue({
            serviceChargeEnabled: true,
            serviceChargePercent: '10',
            defaultTaxRateId: 'tax-1',
            taxIncluded: false,
          }),
        },
        orderItems: {
          findMany: jest
            .fn()
            .mockResolvedValue([{ lineTotal: '100' }, { lineTotal: '50' }]),
        },
        taxRates: {
          findFirst: jest.fn().mockResolvedValue({ rate: '7' }),
        },
      },
      update: jest.fn().mockReturnValue({ set: setMock }),
    };

    const service = new OrderCalculationService(mockDb);

    await service.recalculateOrderTotals('tenant-1', 'order-1');

    expect(setMock).toHaveBeenCalled();
    const payload = setMock.mock.calls[0][0];
    expect(payload.subtotal).toBe('150');
    expect(payload.serviceChargeAmount).toBe('14');
    expect(payload.taxAmount).toBe('10.78');
    expect(payload.totalAmount).toBe('164.78');
  });
});
