import 'package:drift/drift.dart';
import '../app_database.dart';

part 'sync_queue_dao.g.dart';

/// 16.2.6 backing DAO — all raw DB operations for the sync queue.
@DriftAccessor(tables: [LocalSyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<void> enqueue(LocalSyncQueueCompanion item) =>
      into(localSyncQueue)
          .insert(item, mode: InsertMode.insertOrReplace);

  /// Returns pending + failed items that have not exceeded [maxAttempts].
  Future<List<LocalSyncQueueRow>> getPendingItems({
    int limit = 50,
    int maxAttempts = 5,
  }) =>
      (select(localSyncQueue)
            ..where(
              (q) => q.status.isIn(const ['pending', 'failed']) &
                  q.attempts.isSmallerOrEqualValue(maxAttempts),
            )
            ..orderBy([(q) => OrderingTerm.asc(q.clientTimestamp)])
            ..limit(limit))
          .get();

  Future<int> getPendingCount({int maxAttempts = 5}) async {
    final count = localSyncQueue.id.count();
    final query = selectOnly(localSyncQueue)
      ..addColumns([count])
      ..where(
        localSyncQueue.status.isIn(const ['pending', 'failed']) &
            localSyncQueue.attempts.isSmallerOrEqualValue(maxAttempts),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> markSyncing(List<String> ids) =>
      (update(localSyncQueue)..where((q) => q.id.isIn(ids))).write(
        const LocalSyncQueueCompanion(status: Value('syncing')),
      );

  Future<void> markCompleted(String id) =>
      (update(localSyncQueue)..where((q) => q.id.equals(id))).write(
        const LocalSyncQueueCompanion(status: Value('completed')),
      );

  Future<void> markFailed(String id, String error) async {
    final item = await (select(localSyncQueue)
          ..where((q) => q.id.equals(id)))
        .getSingleOrNull();
    if (item == null) return;
    await (update(localSyncQueue)..where((q) => q.id.equals(id))).write(
      LocalSyncQueueCompanion(
        status: const Value('failed'),
        attempts: Value(item.attempts + 1),
        errorMessage: Value(error),
      ),
    );
  }

  /// Reset items stuck in 'syncing' (e.g., after app crash) back to 'pending'.
  Future<void> resetStuckSyncing() =>
      (update(localSyncQueue)
            ..where((q) => q.status.equals('syncing')))
          .write(
        const LocalSyncQueueCompanion(status: Value('pending')),
      );

  Future<void> deleteCompleted() =>
      (delete(localSyncQueue)
            ..where((q) => q.status.equals('completed')))
          .go();
}
