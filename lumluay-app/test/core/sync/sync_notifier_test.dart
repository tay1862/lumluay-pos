import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/core/sync/sync_notifier.dart';

void main() {
  test('SyncNotifier transitions syncing -> idle -> error', () {
    final notifier = SyncNotifier();

    notifier.setSyncing();
    expect(notifier.state.status, SyncStatus.syncing);

    notifier.updatePendingCount(3);
    expect(notifier.state.pendingCount, 3);

    final now = DateTime.now();
    notifier.setIdle(syncedAt: now);
    expect(notifier.state.status, SyncStatus.idle);
    expect(notifier.state.lastSyncAt, now);

    notifier.setError('network error');
    expect(notifier.state.status, SyncStatus.error);
    expect(notifier.state.lastError, 'network error');
  });
}
