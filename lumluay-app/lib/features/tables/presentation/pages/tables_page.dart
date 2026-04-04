import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/tables_repository.dart';
import '../../../pos/providers/cart_provider.dart';

class TablesPage extends ConsumerWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesProvider);
    final selectedZoneId = ref.watch(selectedZoneIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ผังโต๊ะ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'จัดการโซน',
            onPressed: () => context.push('/settings/zones'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(tablesRepositoryProvider).invalidateCache();
              ref.invalidate(zonesProvider);
              ref.read(tableReloadSeedProvider.notifier).state++;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone tabs
          zonesAsync.when(
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox.shrink(),
            data: (zones) => _ZoneTabs(zones: zones),
          ),
          // Tables grid
          Expanded(
            child: _TablesGrid(zoneId: selectedZoneId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('เปิดโต๊ะใหม่'),
        onPressed: () => _showOpenTableDialog(context, ref),
      ),
    );
  }

  void _showOpenTableDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _OpenTableDialog(ref: ref),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Open Table Dialog — picker for available tables
// ─────────────────────────────────────────────────────────────────────────────
class _OpenTableDialog extends ConsumerStatefulWidget {
  const _OpenTableDialog({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_OpenTableDialog> createState() => _OpenTableDialogState();
}

class _OpenTableDialogState extends ConsumerState<_OpenTableDialog> {
  String? _selectedTableId;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider(null));

    return AlertDialog(
      title: const Text('เปิดโต๊ะใหม่'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: 400.w,
        child: tablesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
          data: (tables) {
            final available = tables
                .where((t) => t.status == TableStatus.available)
                .toList();

            if (available.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('ไม่มีโต๊ะว่าง'),
              );
            }

            return Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: available
                  .map(
                    (t) => ChoiceChip(
                      label: Text(t.name),
                      selected: _selectedTableId == t.id,
                      onSelected: (_) =>
                          setState(() => _selectedTableId = t.id),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
      actions: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _selectedTableId == null || _loading ? null : _confirm,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('เปิดโต๊ะ'),
        ),
      ],
    );
  }

  Future<void> _confirm() async {
    if (_selectedTableId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(tablesRepositoryProvider)
          .updateStatus(_selectedTableId!, 'occupied');
      ref.read(tableReloadSeedProvider.notifier).state++;
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Zone tab bar
// ─────────────────────────────────────────────────────────────────────────────
class _ZoneTabs extends ConsumerWidget {
  const _ZoneTabs({required this.zones});
  final List<ZoneModel> zones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedZoneIdProvider);
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      height: 48.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        children: [
          _ZoneChip(label: 'ทั้งหมด', selected: selectedId == null, onTap: () {
            ref.read(selectedZoneIdProvider.notifier).state = null;
          }),
          ...zones.map((z) => _ZoneChip(
                label: z.name,
                selected: selectedId == z.id,
                onTap: () =>
                    ref.read(selectedZoneIdProvider.notifier).state = z.id,
              )),
        ],
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(right: 6.w),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tables grid
// ─────────────────────────────────────────────────────────────────────────────
class _TablesGrid extends ConsumerWidget {
  const _TablesGrid({required this.zoneId});
  final String? zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider(zoneId));
    return tablesAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (tables) {
        if (tables.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.table_restaurant, size: 48, color: Colors.black26),
                SizedBox(height: 12),
                Text('ไม่มีโต๊ะ', style: TextStyle(color: Colors.black54)),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: EdgeInsets.all(12.w),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160.w,
            mainAxisExtent: 130.h,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
          ),
          itemCount: tables.length,
          itemBuilder: (ctx, i) => _TableCard(table: tables[i], zoneId: zoneId),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table card
// ─────────────────────────────────────────────────────────────────────────────
class _TableCard extends ConsumerWidget {
  const _TableCard({required this.table, required this.zoneId});
  final TableModel table;
  final String? zoneId;

  Color _statusColor(BuildContext context) => switch (table.status) {
    TableStatus.occupied => Colors.red[100]!,
    TableStatus.reserved => Colors.amber[100]!,
    TableStatus.cleaning => Colors.blueGrey[100]!,
        _ => Colors.green[50]!,
      };

  Color _statusBorderColor() => switch (table.status) {
    TableStatus.occupied => Colors.red,
    TableStatus.reserved => Colors.amber[700]!,
    TableStatus.cleaning => Colors.blueGrey,
        _ => Colors.green,
      };

  String _statusLabel() => switch (table.status) {
    TableStatus.occupied => 'มีคนอยู่',
    TableStatus.reserved => 'จอง',
    TableStatus.cleaning => 'ทำความสะอาด',
        _ => 'ว่าง',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmtMoney = NumberFormat('#,##0');
    final elapsed = table.occupiedSince != null
        ? DateTime.now().difference(table.occupiedSince!).inMinutes
        : null;

    return GestureDetector(
      onTap: () => _onTap(context),
      onLongPress: () => _showActionSheet(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _statusColor(context),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _statusBorderColor(), width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    table.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _statusBorderColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(_statusLabel(),
                      style: TextStyle(
                          color: _statusBorderColor(),
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.people_outline,
                    size: 12.sp, color: Colors.black45),
                SizedBox(width: 3.w),
                Text('${table.seats}',
                    style: TextStyle(
                        fontSize: 11.sp, color: Colors.black54)),
              ],
            ),
            const Spacer(),
            if (table.currentOrderTotal != null)
              Text(
                '฿${fmtMoney.format(table.currentOrderTotal)}',
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.red[700]),
              ),
            if (elapsed != null)
              Text(
                '$elapsed นาที',
                style: TextStyle(fontSize: 10.sp, color: Colors.black45),
              ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    if (table.status == TableStatus.available) {
      context.push('/pos?tableId=${table.id}&tableName=${table.name}');
    } else if (table.status == TableStatus.occupied && table.currentOrderId != null) {
      context.push('/orders/${table.currentOrderId}');
    }
  }

  Future<void> _showActionSheet(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(tablesRepositoryProvider);

    Future<void> refreshData() async {
      repo.invalidateCache();
      ref.invalidate(zonesProvider);
      ref.read(tableReloadSeedProvider.notifier).state++;
    }

    Future<void> openPosForTable() async {
      ref.read(cartProvider.notifier).setTable(table.id, table.name);
      if (context.mounted) {
        context.push('/pos?tableId=${table.id}&tableName=${table.name}');
      }
    }

    Future<void> moveTableFlow() async {
      final allTables = await repo.getTables(forceRefresh: true);
      final options = allTables
          .where((t) => t.id != table.id && t.status == TableStatus.available)
          .toList();
      if (options.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่มีโต๊ะว่างสำหรับย้าย')),
          );
        }
        return;
      }

      if (!context.mounted) return;
      final target = await showDialog<TableModel>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('ย้ายไปโต๊ะ'),
          children: options
              .map(
                (t) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, t),
                  child: Text(t.name),
                ),
              )
              .toList(),
        ),
      );
      if (target == null) return;

      await repo.moveTable(sourceTableId: table.id, targetTableId: target.id);
      await refreshData();
    }

    Future<void> mergeTableFlow() async {
      final allTables = await repo.getTables(forceRefresh: true);
      final candidates = allTables
          .where((t) => t.id != table.id && t.status == TableStatus.occupied)
          .toList();
      if (candidates.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่มีโต๊ะที่รวมได้')),
          );
        }
        return;
      }

      if (!context.mounted) return;
      final selected = <String>{};
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text('รวมเข้ากับ ${table.name}'),
            content: SizedBox(
              width: 320,
              child: ListView(
                shrinkWrap: true,
                children: candidates
                    .map(
                      (t) => CheckboxListTile(
                        value: selected.contains(t.id),
                        title: Text(t.name),
                        onChanged: (v) {
                          setDialogState(() {
                            if (v == true) {
                              selected.add(t.id);
                            } else {
                              selected.remove(t.id);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('รวม')),
            ],
          ),
        ),
      );

      if (ok != true || selected.isEmpty) return;
      await repo.mergeTables(
        targetTableId: table.id,
        mergeTableIds: selected.toList(),
      );
      await refreshData();
    }

    Future<void> splitTableFlow() async {
      final orderId = table.currentOrderId;
      if (orderId == null) {
        throw Exception('ไม่พบออเดอร์ที่โต๊ะนี้');
      }

      final allTables = await repo.getTables(forceRefresh: true);
      final targetOptions = allTables
          .where((t) => t.id != table.id && t.status == TableStatus.available)
          .toList();
      if (targetOptions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่มีโต๊ะว่างสำหรับแยกบิล')),
          );
        }
        return;
      }

      if (!context.mounted) return;
      final target = await showDialog<TableModel>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('เลือกโต๊ะปลายทาง'),
          children: targetOptions
              .map((t) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, t),
                    child: Text(t.name),
                  ))
              .toList(),
        ),
      );
      if (target == null) return;

      final items = await repo.getOrderItems(orderId);
      final selectedItemIds = <String>{};

      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('เลือกรายการที่จะแยก'),
            content: SizedBox(
              width: 360,
              child: ListView(
                shrinkWrap: true,
                children: items
                    .map(
                      (item) => CheckboxListTile(
                        value: selectedItemIds.contains('${item['id']}'),
                        title: Text('${item['productName']} x${item['quantity']}'),
                        subtitle: Text('฿${item['lineTotal']}'),
                        onChanged: (v) {
                          setDialogState(() {
                            final id = '${item['id']}';
                            if (v == true) {
                              selectedItemIds.add(id);
                            } else {
                              selectedItemIds.remove(id);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('แยก')),
            ],
          ),
        ),
      );

      if (confirmed != true || selectedItemIds.isEmpty) return;

      await repo.splitTable(
        sourceTableId: table.id,
        targetTableId: target.id,
        orderItemIds: selectedItemIds.toList(),
      );
      await refreshData();
    }

    Future<void> showQrCode() async {
      final qr = await repo.getTableQrCode(table.id);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('QR URL โต๊ะ'),
          content: SelectableText('${qr['url'] ?? ''}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ปิด')),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(table.name,
                  style: TextStyle(
                      fontSize: 16.sp, fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 1),
            if (table.status == TableStatus.available) ...[
              ListTile(
                leading: const Icon(Icons.point_of_sale),
                title: const Text('เปิดออเดอร์'),
                onTap: () {
                  Navigator.pop(context);
                  openPosForTable();
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_seat),
                title: const Text('ตั้งเป็นจอง'),
                onTap: () async {
                  Navigator.pop(context);
                  await repo.updateStatus(table.id, 'reserved');
                  if (!context.mounted) return;
                  await refreshData();
                },
              ),
            ],
            if (table.status == TableStatus.occupied)
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('ดูออเดอร์'),
                onTap: () {
                  Navigator.pop(context);
                  if (table.currentOrderId != null) {
                    context.push('/orders/${table.currentOrderId}');
                  }
                },
              ),
            if (table.status == TableStatus.occupied)
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('ย้ายโต๊ะ'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await moveTableFlow();
                  } catch (e) {
                    if (context.mounted) { // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
              ),
            if (table.status == TableStatus.occupied)
              ListTile(
                leading: const Icon(Icons.call_merge),
                title: const Text('รวมโต๊ะ'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await mergeTableFlow();
                  } catch (e) {
                    if (context.mounted) { // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
              ),
            if (table.status == TableStatus.occupied)
              ListTile(
                leading: const Icon(Icons.call_split),
                title: const Text('แยกโต๊ะ'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await splitTableFlow();
                  } catch (e) {
                    if (context.mounted) { // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
              ),
            if (table.status == TableStatus.reserved)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('เปลี่ยนเป็นว่าง'),
                onTap: () async {
                  Navigator.pop(context);
                  await repo.updateStatus(table.id, 'available');
                  if (!context.mounted) return;
                  await refreshData();
                },
              ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('ดู QR โต๊ะ'),
              onTap: () async {
                Navigator.pop(context);
                await showQrCode();
              },
            ),
          ],
        ),
      ),
    );
  }
}
