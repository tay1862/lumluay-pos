import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/sync_queue_dao.dart';

/// 16.2.6 — High-level Sync Queue Manager.
/// Wraps [SyncQueueDao] and provides a clean API for enqueueing and
/// managing offline operations.
class SyncQueueManager {
  SyncQueueManager(this._dao);

  final SyncQueueDao _dao;
  static const _uuid = Uuid();

  /// Enqueue a single operation for later sync.
  Future<void> enqueue({
    required String operation, // create | update | delete
    required String entityType, // product | order | payment | shift | member
    String? entityId,
    required Map<String, dynamic> payload,
    String? checksum,
  }) async {
    await _dao.enqueue(
      LocalSyncQueueCompanion(
        id: Value(_uuid.v4()),
        operation: Value(operation),
        entityType: Value(entityType),
        entityId: Value(entityId),
        payload: Value(jsonEncode(payload)),
        checksum: Value(checksum),
        status: const Value('pending'),
        attempts: const Value(0),
        clientTimestamp: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<List<LocalSyncQueueRow>> getPendingItems({
    int limit = 50,
    int maxAttempts = 5,
  }) =>
      _dao.getPendingItems(limit: limit, maxAttempts: maxAttempts);

  Future<int> getPendingCount() => _dao.getPendingCount();

  Future<void> markCompleted(String id) => _dao.markCompleted(id);

  Future<void> markFailed(String id, String error) =>
      _dao.markFailed(id, error);

  Future<void> markSyncing(List<String> ids) => _dao.markSyncing(ids);

  /// Reset items that were left in 'syncing' state (e.g. after a crash).
  Future<void> resetStuck() => _dao.resetStuckSyncing();

  /// Remove completed entries to keep the queue table lean.
  Future<void> cleanup() => _dao.deleteCompleted();
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final syncQueueManagerProvider = Provider<SyncQueueManager>((ref) {
  final dao = ref.watch(appDatabaseProvider).syncQueueDao;
  return SyncQueueManager(dao);
});
