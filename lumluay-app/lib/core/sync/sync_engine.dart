import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_client.dart';
import '../services/connectivity_service.dart';
import '../database/app_database.dart';
import 'sync_queue_manager.dart';
import 'sync_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 16.2.7 — Sync Engine
// ─────────────────────────────────────────────────────────────────────────────

const _batchSize = 50;
const _maxAttempts = 5;
const _timerInterval = Duration(seconds: 30);
const _deviceIdKey = 'sync_device_id';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    api: ref.read(apiClientProvider),
    db: ref.read(appDatabaseProvider),
    queueManager: ref.read(syncQueueManagerProvider),
    connectivity: ref.read(connectivityServiceProvider),
    notifier: ref.read(syncNotifierProvider.notifier),
  );
  ref.onDispose(engine.stop);
  return engine;
});

class SyncEngine {
  SyncEngine({
    required ApiClient api,
    required AppDatabase db,
    required SyncQueueManager queueManager,
    required ConnectivityService connectivity,
    required SyncNotifier notifier,
  })  : _api = api,
        _db = db,
        _queueManager = queueManager,
        _connectivity = connectivity,
        _notifier = notifier;

  final ApiClient _api;
  final AppDatabase _db;
  final SyncQueueManager _queueManager;
  final ConnectivityService _connectivity;
  final SyncNotifier _notifier;
  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  Timer? _timer;
  bool _isSyncing = false;
  DateTime? _lastSyncAt;
  String? _deviceId;

  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    _deviceId = await _storage.read(key: _deviceIdKey);
    if (_deviceId == null) {
      _deviceId = _uuid.v4();
      await _storage.write(key: _deviceIdKey, value: _deviceId);
    }
    return _deviceId!;
  }

  /// Starts the background sync timer and resets any stuck entries.
  void start() {
    stop();
    _queueManager.resetStuck();
    _timer = Timer.periodic(_timerInterval, (_) => performSync());
  }

  /// Cancels the background timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Full push + pull cycle. Skips if offline or already syncing.
  Future<void> performSync() async {
    if (_isSyncing) return;
    final online = await _connectivity.isOnline;
    if (!online) return;

    _isSyncing = true;
    _notifier.setSyncing();
    try {
      await _pushPending();
      await _pullChanges();
      final pending = await _queueManager.getPendingCount();
      _notifier.updatePendingCount(pending);
      _lastSyncAt = DateTime.now();
      _notifier.setIdle(syncedAt: _lastSyncAt);
    } catch (e) {
      _notifier.setError(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Called once after login to pull all data and seed the local DB.
  Future<void> performInitialSync() async {
    final online = await _connectivity.isOnline;
    if (!online) return;

    _isSyncing = true;
    _notifier.setSyncing();
    try {
      await _pullChanges(since: '');
      _lastSyncAt = DateTime.now();
      _notifier.setIdle(syncedAt: _lastSyncAt);
    } catch (e) {
      _notifier.setError(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  // ── Push ──────────────────────────────────────────────────────────────────

  Future<void> _pushPending() async {
    final pending = await _queueManager.getPendingItems(
      limit: _batchSize,
      maxAttempts: _maxAttempts,
    );
    if (pending.isEmpty) return;

    final ids = pending.map((e) => e.id).toList();
    await _queueManager.markSyncing(ids);

    final deviceId = await _getDeviceId();

    // Build operations matching backend PushSyncDto
    final operations = pending
        .map((e) => {
              'operation': e.operation,
              'entityType': e.entityType,
              if (e.entityId != null) 'entityId': e.entityId,
              'payload': e.payload.startsWith('{')
                  ? jsonDecode(e.payload)
                  : e.payload,
              if (e.checksum != null) 'checksum': e.checksum,
              'clientTimestamp': e.clientTimestamp,
            })
        .toList();

    try {
      final result = await _api.post<Map<String, dynamic>>(
        '/sync/push',
        data: {'deviceId': deviceId, 'operations': operations},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );

      final results =
          (result['results'] as List? ?? []).cast<Map<String, dynamic>>();
      // Backend returns results in same order as operations
      for (var i = 0; i < results.length && i < ids.length; i++) {
        final r = results[i];
        final id = ids[i];
        final status = r['status'] as String? ?? 'error';
        if (status == 'applied' || status == 'ok') {
          await _queueManager.markCompleted(id);
        } else {
          await _queueManager.markFailed(
              id, r['error'] as String? ?? 'unknown');
        }
      }
      // Any id without a result → mark failed
      for (var i = results.length; i < ids.length; i++) {
        await _queueManager.markFailed(ids[i], 'no response from server');
      }
    } catch (e) {
      for (final id in ids) {
        await _queueManager.markFailed(id, e.toString());
      }
      rethrow;
    }
  }

  // ── Pull ──────────────────────────────────────────────────────────────────

  Future<void> _pullChanges({String? since}) async {
    final sinceParam = since ?? _lastSyncAt?.toIso8601String() ?? '';
    final deviceId = await _getDeviceId();

    final result = await _api.get<Map<String, dynamic>>(
      '/sync/pull',
      queryParameters: {'since': sinceParam, 'deviceId': deviceId},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );

    // Backend returns { deviceId, serverTime, since, data: { products, categories, members } }
    final innerData = result['data'] as Map<String, dynamic>? ?? result;
    await _applyPull(innerData);
  }

  Future<void> _applyPull(Map<String, dynamic> data) async {
    final now = DateTime.now().toIso8601String();

    // Categories
    final rawCategories =
        (data['categories'] as List? ?? []).cast<Map<String, dynamic>>();
    for (final c in rawCategories) {
      await _db.productsDao.upsertCategory(
        LocalCategoriesCompanion.insert(
          id: '${c['id']}',
          name: '${c['name']}',
          sortOrder: Value(int.tryParse('${c['sortOrder'] ?? 0}') ?? 0),
          isActive: Value((c['isActive'] as bool?) ?? true),
          updatedAt: '${c['updatedAt'] ?? now}',
        ),
      );
    }

    // Products
    final rawProducts =
        (data['products'] as List? ?? []).cast<Map<String, dynamic>>();
    for (final p in rawProducts) {
      await _db.productsDao.upsertProduct(
        LocalProductsCompanion.insert(
          id: '${p['id']}',
          categoryId: Value(p['categoryId'] != null ? '${p['categoryId']}' : null),
          name: '${p['name']}',
          basePrice: Value(double.tryParse('${p['basePrice'] ?? 0}') ?? 0),
          sku: Value(p['sku'] != null ? '${p['sku']}' : null),
          imageUrl: Value(p['imageUrl'] != null ? '${p['imageUrl']}' : null),
          productType: Value('${p['productType'] ?? 'simple'}'),
          isActive: Value((p['isActive'] as bool?) ?? true),
          updatedAt: '${p['updatedAt'] ?? now}',
        ),
      );
    }
  }
}
