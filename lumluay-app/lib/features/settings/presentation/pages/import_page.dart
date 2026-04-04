import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

enum ImportStatus { idle, picking, uploading, success, failure }

class _ImportState {
  final ImportStatus status;
  final String? message;
  final String importType;

  const _ImportState({
    this.status = ImportStatus.idle,
    this.message,
    this.importType = 'products',
  });

  _ImportState copyWith(
          {ImportStatus? status, String? message, String? importType}) =>
      _ImportState(
        status: status ?? this.status,
        message: message ?? this.message,
        importType: importType ?? this.importType,
      );
}

class _ImportNotifier extends StateNotifier<_ImportState> {
  final ApiClient _client;

  _ImportNotifier(this._client) : super(const _ImportState());

  Future<void> pickAndUpload(String type) async {
    state = state.copyWith(status: ImportStatus.picking, importType: type);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.isEmpty) {
      state = state.copyWith(status: ImportStatus.idle);
      return;
    }

    final path = result.files.single.path;
    final bytes = result.files.single.bytes;

    state = state.copyWith(status: ImportStatus.uploading);

    try {
      FormData formData;
      if (kIsWeb && bytes != null) {
        // On web, file path is unavailable; use the in-memory bytes instead.
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: 'import.csv'),
        });
      } else if (path != null) {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(path, filename: 'import.csv'),
        });
      } else {
        state = state.copyWith(status: ImportStatus.idle);
        return;
      }

      // Use ApiClient which handles multipart/form-data
      await _client.post<dynamic>(
        '/import-export/import/$type',
        data: formData,
      );

      state = state.copyWith(
        status: ImportStatus.success,
        message: 'Import completed successfully',
      );
    } catch (e) {
      state = state.copyWith(
        status: ImportStatus.failure,
        message: e.toString(),
      );
    }
  }

  void reset() => state = const _ImportState();
}

final _importProvider =
    StateNotifierProvider<_ImportNotifier, _ImportState>((ref) {
  return _ImportNotifier(ref.watch(apiClientProvider));
});

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class ImportPage extends ConsumerWidget {
  const ImportPage({super.key});

  static const routePath = '/settings/import';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_importProvider);
    final notifier = ref.read(_importProvider.notifier);
    final theme = Theme.of(context);

    if (state.status == ImportStatus.success ||
        state.status == ImportStatus.failure) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message ?? ''),
            backgroundColor: state.status == ImportStatus.success
                ? Colors.green
                : theme.colorScheme.error,
          ),
        );
        notifier.reset();
      });
    }

    final isLoading = state.status == ImportStatus.uploading ||
        state.status == ImportStatus.picking;

    return Scaffold(
      appBar: AppBar(title: const Text('Import Data')),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          // CSV template info card
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.onSecondaryContainer),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'CSV files must match the required column order. '
                      'Download the template from the Export page first.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _ImportTile(
            title: 'Import Products',
            subtitle: 'Upload a products CSV file',
            icon: Icons.inventory_2_outlined,
            isLoading: isLoading,
            onImport: () => notifier.pickAndUpload('products'),
          ),
        ],
      ),
    );
  }
}

class _ImportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onImport;

  const _ImportTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isLoading,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.upload, size: 16),
                label: const Text('Import'),
              ),
      ),
    );
  }
}
