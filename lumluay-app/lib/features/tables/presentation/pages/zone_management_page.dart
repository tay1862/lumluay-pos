import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/tables_repository.dart';

class ZoneManagementPage extends ConsumerWidget {
  const ZoneManagementPage({super.key});

  Future<void> _createZone(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final sortCtrl = TextEditingController(text: '0');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ເພີ່ມໂຊນ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ຊື່ໂຊນ')),
            SizedBox(height: 8.h),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'ລາຍລະອຽດ')),
            SizedBox(height: 8.h),
            TextField(
              controller: sortCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ລຳດັບ'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ຍົກເລີກ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ບັນທຶກ')),
        ],
      ),
    );

    if (ok != true || nameCtrl.text.trim().isEmpty) return;

    await ref.read(tablesRepositoryProvider).createZone(
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          sortOrder: int.tryParse(sortCtrl.text) ?? 0,
        );
    ref.invalidate(zonesProvider);
  }

  Future<void> _editZone(BuildContext context, WidgetRef ref, ZoneModel zone) async {
    final nameCtrl = TextEditingController(text: zone.name);
    final descCtrl = TextEditingController(text: zone.description ?? '');
    final sortCtrl = TextEditingController(text: zone.sortOrder.toString());

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ແກ້ໄຂໂຊນ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ຊື່ໂຊນ')),
            SizedBox(height: 8.h),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'ລາຍລະອຽດ')),
            SizedBox(height: 8.h),
            TextField(
              controller: sortCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ລຳດັບ'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'delete'), child: const Text('ລົບ')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('ຍົກເລີກ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('ບັນທຶກ')),
        ],
      ),
    );

    if (action == 'save') {
      await ref.read(tablesRepositoryProvider).updateZone(
            id: zone.id,
            name: nameCtrl.text.trim(),
            description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
            sortOrder: int.tryParse(sortCtrl.text) ?? 0,
          );
      ref.invalidate(zonesProvider);
    } else if (action == 'delete') {
      try {
        await ref.read(tablesRepositoryProvider).deleteZone(zone.id);
        ref.invalidate(zonesProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ຈັດການໂຊນ'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createZone(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('ເພີ່ມໂຊນ'),
      ),
      body: zonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (zones) {
          if (zones.isEmpty) {
            return const Center(child: Text('ຍັງບໍ່ມີໂຊນ'));
          }
          return ListView.separated(
            itemCount: zones.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final zone = zones[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${zone.sortOrder}')),
                title: Text(zone.name),
                subtitle: Text(zone.description ?? '-'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editZone(context, ref, zone),
              );
            },
          );
        },
      ),
    );
  }
}
