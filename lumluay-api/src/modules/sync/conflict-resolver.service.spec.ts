import { ConflictResolverService } from './conflict-resolver.service';

describe('ConflictResolverService', () => {
  it('returns applied for unknown entity types without throwing', async () => {
    const service = new ConflictResolverService({} as any);

    const result = await service.resolveOperation('tenant-1', {
      operation: 'update',
      entityType: 'unknown_entity',
      entityId: '11111111-1111-1111-1111-111111111111',
      payload: {},
      clientTimestamp: new Date().toISOString(),
    });

    expect(result.status).toBe('applied');
  });
});
