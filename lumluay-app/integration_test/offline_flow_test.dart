import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lumluay_pos/core/sync/sync_notifier.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('18.2.8 Offline flow smoke (sync state)', (tester) async {
    final notifier = SyncNotifier();

    notifier.setError('offline');
    expect(notifier.state.hasError, isTrue);

    notifier.setSyncing();
    notifier.setIdle(syncedAt: DateTime.now());

    expect(notifier.state.status, SyncStatus.idle);
  });
}
