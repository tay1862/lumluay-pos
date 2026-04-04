import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State & providers
// ─────────────────────────────────────────────────────────────────────────────

enum _BackupStatus { idle, loading, error }

class _BackupState {
  final _BackupStatus status;
  final List<Map<String, dynamic>> backups;
  final String? error;

  const _BackupState({
    this.status = _BackupStatus.idle,
    this.backups = const [],
    this.error,
  });

  _BackupState copyWith(
          {_BackupStatus? status,
          List<Map<String, dynamic>>? backups,
          String? error}) =>
      _BackupState(
        status: status ?? this.status,
        backups: backups ?? this.backups,
        error: error ?? this.error,
      );
}

class _BackupNotifier extends StateNotifier<_BackupState> {
  final ApiClient _client;

  _BackupNotifier(this._client) : super(const _BackupState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(status: _BackupStatus.loading);
    try {
      final data = await _client.get<List<dynamic>>('/backup');
      state = state.copyWith(
        status: _BackupStatus.idle,
        backups: data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(
          status: _BackupStatus.error, error: e.toString());
    }
  }

  Future<void> triggerBackup() async {
    state = state.copyWith(status: _BackupStatus.loading);
    try {
      await _client.post<dynamic>('/backup', data: {});
      await load();
    } catch (e) {
      state = state.copyWith(
          status: _BackupStatus.error, error: e.toString());
    }
  }
}

final _backupNotifierProvider =
    StateNotifierProvider<_BackupNotifier, _BackupState>((ref) {
  return _BackupNotifier(ref.watch(apiClientProvider));
});

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class BackupSettingsPage extends ConsumerWidget {
  const BackupSettingsPage({super.key});

  static const routePath = '/settings/backup';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_backupNotifierProvider);
    final notifier = ref.read(_backupNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Manual backup trigger
          Padding(
            padding: EdgeInsets.all(16.r),
            child: ElevatedButton.icon(
              onPressed: state.status == _BackupStatus.loading
                  ? null
                  : notifier.triggerBackup,
              icon: state.status == _BackupStatus.loading
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.backup),
              label: const Text('Create Backup Now'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 44.h),
              ),
            ),
          ),

          if (state.error != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Text(
                    state.error!,
                    style: TextStyle(
                        color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ),

          Divider(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                const Icon(Icons.history, size: 18),
                SizedBox(width: 8.w),
                Text('Backup Files',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Expanded(
            child: state.backups.isEmpty
                ? Center(
                    child: Text(
                      'No backups found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4)),
                    ),
                  )
                : ListView.builder(
                    itemCount: state.backups.length,
                    itemBuilder: (_, i) {
                      final backup = state.backups[i];
                      final name = '${backup['name']}';
                      final size = (backup['size'] as num?)?.toInt() ?? 0;
                      final sizeStr = _formatSize(size);

                      return ListTile(
                        leading: const Icon(Icons.archive_outlined),
                        title: Text(
                          name,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(sizeStr),
                        trailing: const Icon(Icons.check_circle,
                            color: Colors.green, size: 18),
                        dense: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
