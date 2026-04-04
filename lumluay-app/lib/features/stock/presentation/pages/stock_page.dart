import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/stock_repository.dart';

// Filter: all | low | out
final _stockFilterProvider = StateProvider<String>((ref) => 'all');

class StockPage extends ConsumerWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_stockFilterProvider);
    final stockAsync = ref.watch(stockListProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('สต็อกสินค้า'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'ภาพรวม'),
              Tab(icon: Icon(Icons.history), text: 'ความเคลื่อนไหว'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(stockListProvider);
                ref.invalidate(stockMovementsProvider);
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Overview
            Column(
              children: [
                // Filter chips
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Row(
                    children: [
                      _FilterChip(label: 'ทั้งหมด', value: 'all', groupValue: filter),
                      SizedBox(width: 8.w),
                      _FilterChip(label: 'ใกล้หมด', value: 'low', groupValue: filter),
                      SizedBox(width: 8.w),
                      _FilterChip(label: 'หมด', value: 'out', groupValue: filter),
                    ],
                  ),
                ),
                Expanded(
                  child: stockAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (items) {
                      final filtered = filter == 'all'
                          ? items
                          : items.where((i) => i.status == filter).toList();
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            filter == 'low'
                                ? 'ไม่มีสินค้าใกล้หมด'
                                : filter == 'out'
                                    ? 'ไม่มีสินค้าหมด'
                                    : 'ไม่มีข้อมูลสต็อก',
                            style:
                                const TextStyle(color: Colors.black54),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (ctx, i) =>
                            _StockItemTile(item: filtered[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Tab 2: Movement history
            _MovementsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.tune),
          label: const Text('ปรับสต็อก'),
          onPressed: () => _showAdjustDialog(context, ref),
        ),
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _AdjustStockDialog(),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  const _FilterChip(
      {required this.label,
      required this.value,
      required this.groupValue});
  final String label;
  final String value;
  final String groupValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FilterChip(
        label: Text(label),
        selected: groupValue == value,
        showCheckmark: false,
        onSelected: (_) =>
            ref.read(_stockFilterProvider.notifier).state = value,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stock item tile
// ─────────────────────────────────────────────────────────────────────────────
class _StockItemTile extends StatelessWidget {
  const _StockItemTile({required this.item});
  final StockItem item;

  Color _statusColor() => switch (item.status) {
        'out' => Colors.red,
        'low' => Colors.orange,
        _ => Colors.green,
      };

  String _statusLabel() => switch (item.status) {
        'out' => 'หมด',
        'low' => 'ใกล้หมด',
        _ => 'ปกติ',
      };

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return ListTile(
      title: Text(item.productName,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
      subtitle: item.sku != null
          ? Text('SKU: ${item.sku}',
              style: TextStyle(fontSize: 11.sp, color: Colors.black54))
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            fmt.format(item.quantity),
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: _statusColor()),
          ),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: _statusColor().withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(_statusLabel(),
                style: TextStyle(
                    color: _statusColor(),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Movements tab
// ─────────────────────────────────────────────────────────────────────────────
class _MovementsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movAsync = ref.watch(stockMovementsProvider);
    return movAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (movements) {
        if (movements.isEmpty) {
          return const Center(
              child: Text('ไม่มีประวัติ', style: TextStyle(color: Colors.black54)));
        }
        final dateFmt = DateFormat('d MMM yy HH:mm');
        return ListView.separated(
          itemCount: movements.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (ctx, i) {
            final m = movements[i];
            final isPositive = m.quantityChange >= 0;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isPositive
                    ? Colors.green[50]
                    : Colors.red[50],
                child: Icon(
                  isPositive ? Icons.add : Icons.remove,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 18.sp,
                ),
              ),
              title: Text(m.productName,
                  style: TextStyle(fontSize: 13.sp)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_typeLabel(m.type),
                      style: TextStyle(fontSize: 11.sp, color: Colors.black54)),
                  if (m.note != null)
                    Text(m.note!,
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.black38,
                            fontStyle: FontStyle.italic)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : ''}${m.quantityChange}',
                    style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp),
                  ),
                  Text(dateFmt.format(m.createdAt),
                      style:
                          TextStyle(fontSize: 10.sp, color: Colors.black38)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _typeLabel(String type) => switch (type) {
        'purchase' => 'รับเข้า (ซื้อ)',
        'sale' => 'ขายออก',
        'adjustment' => 'ปรับปรุง',
        'damage' => 'เสียหาย',
        'initial' => 'ตั้งต้น',
        _ => type,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Adjust stock dialog
// ─────────────────────────────────────────────────────────────────────────────
class _AdjustStockDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AdjustStockDialog> createState() =>
      _AdjustStockDialogState();
}

class _AdjustStockDialogState extends ConsumerState<_AdjustStockDialog> {
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'adjustment';
  StockItem? _selectedItem;
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedItem == null) return;
    final qty = double.tryParse(_qtyCtrl.text);
    if (qty == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(stockRepositoryProvider).adjust(
        adjustments: [
          {'productId': _selectedItem!.productId, 'quantityChange': qty}
        ],
        type: _type,
        note: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
      );
      ref.invalidate(stockListProvider);
      ref.invalidate(stockMovementsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(stockListProvider);
    return AlertDialog(
      title: const Text('ปรับสต็อก'),
      content: SizedBox(
        width: 320.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product selector
            stockAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('ไม่สามารถโหลดสินค้า'),
              data: (items) => DropdownButtonFormField<StockItem>(
                initialValue: _selectedItem,
                hint: const Text('เลือกสินค้า'),
                items: items
                    .map((i) => DropdownMenuItem(
                          value: i,
                          child: Text(i.productName,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedItem = v),
                decoration:
                    const InputDecoration(labelText: 'สินค้า'),
              ),
            ),
            SizedBox(height: 8.h),
            // Type
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: const [
                DropdownMenuItem(value: 'purchase', child: Text('รับเข้า (ซื้อ)')),
                DropdownMenuItem(value: 'adjustment', child: Text('ปรับปรุง')),
                DropdownMenuItem(value: 'damage', child: Text('เสียหาย')),
                DropdownMenuItem(value: 'initial', child: Text('ตั้งต้น')),
              ],
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(labelText: 'ประเภท'),
            ),
            SizedBox(height: 8.h),
            // Quantity
            TextFormField(
              controller: _qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                  labelText: 'จำนวน (+ เพิ่ม / - ลด)'),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'หมายเหตุ'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('บันทึก'),
        ),
      ],
    );
  }
}
