import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/network/api_client.dart';
import '../../../pos/presentation/widgets/modifier_dialog.dart'
    show ModifierGroup, ModifierOption;

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

class _ModifierGroupsRepository {
  const _ModifierGroupsRepository(this._client);
  final ApiClient _client;

  Future<List<ModifierGroup>> getAll() async {
    final data = await _client.get('/modifier-groups');
    final list = data as List<dynamic>;
    return list
        .map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ModifierGroup> create(Map<String, dynamic> body) async {
    final data = await _client.post('/modifier-groups', data: body);
    return ModifierGroup.fromJson(data as Map<String, dynamic>);
  }

  Future<ModifierGroup> update(String id, Map<String, dynamic> body) async {
    final data = await _client.patch('/modifier-groups/$id', data: body);
    return ModifierGroup.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete('/modifier-groups/$id');
  }

  Future<void> addOption(String groupId, Map<String, dynamic> body) async {
    await _client.post('/modifier-groups/$groupId/options', data: body);
  }

  Future<void> updateOption(
      String groupId, String optionId, Map<String, dynamic> body) async {
    await _client.patch(
        '/modifier-groups/$groupId/options/$optionId',
        data: body);
  }

  Future<void> deleteOption(String groupId, String optionId) async {
    await _client.delete('/modifier-groups/$groupId/options/$optionId');
  }
}

final _modifierGroupsRepoProvider = Provider((ref) {
  return _ModifierGroupsRepository(ref.watch(apiClientProvider));
});

final modifierGroupsListProvider = FutureProvider<List<ModifierGroup>>((ref) {
  return ref.watch(_modifierGroupsRepoProvider).getAll();
});

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class ModifierGroupManagementPage extends ConsumerWidget {
  const ModifierGroupManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(modifierGroupsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ກຸ່ມຕົວເລືອກສິນຄ້າ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'ເພີ່ມກຸ່ມຕົວເລືອກ',
            onPressed: () => _showGroupDialog(context, ref, null),
          ),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48.sp),
              SizedBox(height: 8.h),
              Text('ເກີດຂໍ້ຜິດພາດ: $e'),
              SizedBox(height: 8.h),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(modifierGroupsListProvider),
                child: const Text('ລອງໃໝ່'),
              ),
            ],
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_outlined,
                      size: 64.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  SizedBox(height: 12.h),
                  Text('ຍັງບໍ່ມີກຸ່ມຕົວເລືອກ',
                      style: theme.textTheme.titleMedium),
                  SizedBox(height: 4.h),
                  const Text('ເຊັ່ນ ລະດັບຄວາມເຜັດ, ຂະໜາດຈອກ, ທ໇ອບປິ້ງ'),
                  SizedBox(height: 16.h),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('ເພີ່ມກຸ່ມຕົວເລືອກ'),
                    onPressed: () => _showGroupDialog(context, ref, null),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: groups.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) => _ModifierGroupCard(
              group: groups[index],
              onEdit: () => _showGroupDialog(context, ref, groups[index]),
              onDelete: () => _confirmDeleteGroup(context, ref, groups[index]),
              onAddOption: () =>
                  _showOptionDialog(context, ref, groups[index], null),
              onEditOption: (opt) =>
                  _showOptionDialog(context, ref, groups[index], opt),
              onDeleteOption: (opt) =>
                  _confirmDeleteOption(context, ref, groups[index], opt),
            ),
          );
        },
      ),
    );
  }

  // ── Group dialog ─────────────────────────────────────────────────────────

  void _showGroupDialog(
      BuildContext context, WidgetRef ref, ModifierGroup? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    bool isRequired = existing?.isRequired ?? false;
    bool isMultiple = existing?.isMultiple ?? false;
    final minCtrl = TextEditingController(
        text: existing?.minSelect?.toString() ?? '');
    final maxCtrl = TextEditingController(
        text: existing?.maxSelect?.toString() ?? '');

    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
              existing == null ? 'ເພີ່ມກຸ່ມຕົວເລືອກ' : 'ແກ້ໄຂກຸ່ມຕົວເລືອກ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'ຊື່ກຸ່ມຕົວເລືອກ',
                    hintText: 'ເຊັ່ນ ລະດັບຄວາມເຜັດ',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                SwitchListTile(
                  title: const Text('ບັງຄັບເລືອກ'),
                  subtitle: const Text('ລູກຄ້າຕ້ອງເລືອກກ່ອນສັ່ງ'),
                  value: isRequired,
                  onChanged: (v) => setDialogState(() => isRequired = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('ເລືອກໄດ້ຫຼາຍຢ່າງ'),
                  value: isMultiple,
                  onChanged: (v) => setDialogState(() => isMultiple = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (isMultiple) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'ເລືອກຂັ້ນຕ່ຳ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'ເລືອກສູງສຸດ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ຍົກເລີກ'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(context);
                final body = {
                  'name': name,
                  'isRequired': isRequired,
                  'isMultiple': isMultiple,
                  if (isMultiple && minCtrl.text.isNotEmpty)
                    'minSelect': int.tryParse(minCtrl.text),
                  if (isMultiple && maxCtrl.text.isNotEmpty)
                    'maxSelect': int.tryParse(maxCtrl.text),
                };
                try {
                  final repo = ref.read(_modifierGroupsRepoProvider);
                  if (existing == null) {
                    await repo.create(body);
                  } else {
                    await repo.update(existing.id, body);
                  }
                  ref.invalidate(modifierGroupsListProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e')),
                    );
                  }
                }
              },
              child: const Text('ບັນທຶກ'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Option dialog ────────────────────────────────────────────────────────

  void _showOptionDialog(BuildContext context, WidgetRef ref,
      ModifierGroup group, ModifierOption? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
        text: existing?.priceAdjustment == null
            ? '0'
            : existing!.priceAdjustment.toString());
    bool isDefault = existing?.isDefault ?? false;

    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title:
              Text(existing == null ? 'ເພີ່ມຕົວເລືອກ' : 'ແກ້ໄຂຕົວເລືອກ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'ຊື່ຕົວເລືອກ',
                  hintText: 'ເຊັ່ນ ເຜັດໜ້ອຍ',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'ບວກລາຄາ (ກີບ)',
                  hintText: '0',
                  border: OutlineInputBorder(),
                  prefixText: '+ ₭',
                ),
              ),
              SizedBox(height: 4.h),
              SwitchListTile(
                title: const Text('ຕົວເລືອກເລີ່ມຕົ້ນ'),
                value: isDefault,
                onChanged: (v) => setDialogState(() => isDefault = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ຍົກເລີກ'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(context);
                final body = {
                  'name': name,
                  'priceAdjustment':
                      double.tryParse(priceCtrl.text) ?? 0.0,
                  'isDefault': isDefault,
                };
                try {
                  final repo = ref.read(_modifierGroupsRepoProvider);
                  if (existing == null) {
                    await repo.addOption(group.id, body);
                  } else {
                    await repo.updateOption(group.id, existing.id, body);
                  }
                  ref.invalidate(modifierGroupsListProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e')),
                    );
                  }
                }
              },
              child: const Text('ບັນທຶກ'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirmations ─────────────────────────────────────────────────

  void _confirmDeleteGroup(
      BuildContext context, WidgetRef ref, ModifierGroup group) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ລົບກຸ່ມຕົວເລືອກ'),
        content: Text(
            'ຕ້ອງການລົບກຸ່ມຕົວເລືອກ "${group.name}" ແລະຕົວເລືອກທັງໝົດແມ່ນບໍ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ຍົກເລີກ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('ລົບ'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      try {
        await ref.read(_modifierGroupsRepoProvider).delete(group.id);
        ref.invalidate(modifierGroupsListProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e')),
          );
        }
      }
    });
  }

  void _confirmDeleteOption(BuildContext context, WidgetRef ref,
      ModifierGroup group, ModifierOption option) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ລົບຕົວເລືອກ'),
        content: Text('ຕ້ອງການລົບຕົວເລືອກ "${option.name}" ແມ່ນບໍ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ຍົກເລີກ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('ລົບ'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      try {
        await ref
            .read(_modifierGroupsRepoProvider)
            .deleteOption(group.id, option.id);
        ref.invalidate(modifierGroupsListProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e')),
          );
        }
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modifier group card
// ─────────────────────────────────────────────────────────────────────────────

class _ModifierGroupCard extends StatelessWidget {
  const _ModifierGroupCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
    required this.onAddOption,
    required this.onEditOption,
    required this.onDeleteOption,
  });

  final ModifierGroup group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddOption;
  final void Function(ModifierOption) onEditOption;
  final void Function(ModifierOption) onDeleteOption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group header ─────────────────────────────────────────
          ListTile(
            leading: Icon(Icons.tune_outlined,
                color: theme.colorScheme.primary),
            title: Text(group.name,
                style: theme.textTheme.titleSmall),
            subtitle: Row(
              children: [
                if (group.isRequired)
                  _Badge(
                    label: 'ບັງຄັບ',
                    color: theme.colorScheme.error,
                  ),
                if (group.isRequired && group.isMultiple)
                  SizedBox(width: 4.w),
                if (group.isMultiple)
                  _Badge(
                    label: 'ຫຼາຍລາຍການ',
                    color: theme.colorScheme.secondary,
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('ແກ້ໄຂກຸ່ມ')),
                const PopupMenuItem(
                    value: 'add', child: Text('ເພີ່ມຕົວເລືອກ')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('ລົບກຸ່ມ',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              ],
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    onEdit();
                  case 'add':
                    onAddOption();
                  case 'delete':
                    onDelete();
                }
              },
            ),
          ),

          // ── Options list ─────────────────────────────────────────
          if (group.options.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: Text(
                'ຍັງບໍ່ມີຕົວເລືອກ — ແຕະ "ເພີ່ມຕົວເລືອກ" ເພື່ອເພີ່ມ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            )
          else ...[
            const Divider(height: 1),
            ...group.options.map((opt) {
              return ListTile(
                dense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 0),
                leading: opt.isDefault
                    ? Icon(Icons.star,
                        size: 16.sp, color: Colors.amber)
                    : Icon(Icons.radio_button_unchecked,
                        size: 16.sp,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                title: Text(opt.name),
                subtitle: opt.priceAdjustment > 0
                    ? Text('+₭${opt.priceAdjustment.toStringAsFixed(2)}')
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 18.sp),
                      onPressed: () => onEditOption(opt),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 18.sp,
                          color: theme.colorScheme.error),
                      onPressed: () => onDeleteOption(opt),
                    ),
                  ],
                ),
              );
            }),
          ],

          // ── Add option button ────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: TextButton.icon(
              onPressed: onAddOption,
              icon: Icon(Icons.add, size: 16.sp),
              label: const Text('ເພີ່ມຕົວເລືອກ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
