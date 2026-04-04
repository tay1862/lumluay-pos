import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 16.2.8 — Sync State & Notifier
// ─────────────────────────────────────────────────────────────────────────────

enum SyncStatus { idle, syncing, error }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.lastSyncAt,
    this.lastError,
  });

  final SyncStatus status;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final String? lastError;

  bool get isSyncing => status == SyncStatus.syncing;
  bool get hasError => status == SyncStatus.error;

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    DateTime? lastSyncAt,
    String? lastError,
  }) =>
      SyncState(
        status: status ?? this.status,
        pendingCount: pendingCount ?? this.pendingCount,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        lastError: lastError ?? this.lastError,
      );
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(const SyncState());

  void setSyncing() =>
      state = state.copyWith(status: SyncStatus.syncing, lastError: null);

  void setIdle({DateTime? syncedAt}) => state = state.copyWith(
        status: SyncStatus.idle,
        lastSyncAt: syncedAt ?? state.lastSyncAt,
        lastError: null,
      );

  void setError(String error) =>
      state = state.copyWith(status: SyncStatus.error, lastError: error);

  void updatePendingCount(int count) =>
      state = state.copyWith(pendingCount: count);
}

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});
