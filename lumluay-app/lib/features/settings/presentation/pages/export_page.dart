import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final _exportLoadingProvider = StateProvider<bool>((_) => false);

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class ExportPage extends ConsumerWidget {
  const ExportPage({super.key});

  static const routePath = '/settings/export';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(_exportLoadingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Export Data')),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          _ExportTile(
            title: 'Products',
            subtitle: 'Export all products as CSV',
            icon: Icons.inventory_2_outlined,
            isLoading: isLoading,
            onExport: () => _export(context, ref, 'products'),
          ),
          SizedBox(height: 12.h),
          _ExportTile(
            title: 'Members',
            subtitle: 'Export all members as CSV',
            icon: Icons.people_outline,
            isLoading: isLoading,
            onExport: () => _export(context, ref, 'members'),
          ),
        ],
      ),
    );
  }

  Future<void> _export(
      BuildContext context, WidgetRef ref, String type) async {
    ref.read(_exportLoadingProvider.notifier).state = true;
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get<String>('/import-export/export/$type');
      final csv = response;

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/lumluay-$type-${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'LUMLUAY $type export',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      ref.read(_exportLoadingProvider.notifier).state = false;
    }
  }
}

class _ExportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onExport;

  const _ExportTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isLoading,
    required this.onExport,
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
                onPressed: onExport,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export'),
              ),
      ),
    );
  }
}
