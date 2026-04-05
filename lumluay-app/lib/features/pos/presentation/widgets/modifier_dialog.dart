import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import '../../data/pos_repository.dart';
import '../../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modifier models
// ─────────────────────────────────────────────────────────────────────────────
class ModifierOption {
  final String id;
  final String name;
  final double priceAdjustment;
  final bool isDefault;

  const ModifierOption({
    required this.id,
    required this.name,
    required this.priceAdjustment,
    required this.isDefault,
  });

  factory ModifierOption.fromJson(Map<String, dynamic> j) {
    return ModifierOption(
      id: '${j['id']}',
      name: '${j['name']}',
      priceAdjustment:
          double.tryParse('${j['priceAdjustment'] ?? j['price_adjustment'] ?? 0}') ??
              0,
      isDefault: j['isDefault'] == true,
    );
  }
}

class ModifierGroup {
  final String id;
  final String name;
  final bool isRequired;
  final bool isMultiple;
  final int? minSelect;
  final int? maxSelect;
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.isMultiple,
    this.minSelect,
    this.maxSelect,
    required this.options,
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> j) {
    return ModifierGroup(
      id: '${j['id']}',
      name: '${j['name']}',
      isRequired: j['isRequired'] == true,
      isMultiple: j['isMultiple'] == true || j['multiSelect'] == true,
      minSelect: j['minSelect'] != null ? int.tryParse('${j['minSelect']}') : null,
      maxSelect: j['maxSelect'] != null ? int.tryParse('${j['maxSelect']}') : null,
      options: (j['options'] as List<dynamic>? ?? [])
          .map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Provider to fetch modifier groups for a product
final productModifiersProvider =
    FutureProvider.family<List<ModifierGroup>, String>((ref, productId) async {
  final repo = ref.watch(posRepositoryProvider);
  final raw = await repo.getProductModifiers(productId);
  return raw.map(ModifierGroup.fromJson).toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Modifier Dialog
// ─────────────────────────────────────────────────────────────────────────────
class ModifierDialog extends ConsumerStatefulWidget {
  const ModifierDialog({
    super.key,
    required this.product,
    this.initialQuantity = 1,
    this.initialNote,
  });
  final ProductItem product;
  final int initialQuantity;
  final String? initialNote;

  /// Show the dialog and return a [CartItem] if confirmed, null if cancelled.
  static Future<CartItem?> show(
    BuildContext context, {
    required ProductItem product,
    int initialQuantity = 1,
    String? initialNote,
  }) {
    return showModalBottomSheet<CartItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModifierDialog(
        product: product,
        initialQuantity: initialQuantity,
        initialNote: initialNote,
      ),
    );
  }

  @override
  ConsumerState<ModifierDialog> createState() => _ModifierDialogState();
}

class _ModifierDialogState extends ConsumerState<ModifierDialog> {
  late int _quantity;
  final _noteCtrl = TextEditingController();
  // Map: groupId → Set of selected optionIds
  final Map<String, Set<String>> _selected = {};

  final _fmt = NumberFormat('#,##0.00', 'th_TH');

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    if (widget.initialNote != null) _noteCtrl.text = widget.initialNote!;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _toggleOption(ModifierGroup group, ModifierOption option) {
    setState(() {
      _selected[group.id] ??= {};
      if (!group.isMultiple) {
        // Radio: replace selection
        _selected[group.id] = {option.id};
      } else {
        if (_selected[group.id]!.contains(option.id)) {
          _selected[group.id]!.remove(option.id);
        } else {
          _selected[group.id]!.add(option.id);
        }
      }
    });
  }

  double _calcTotal(List<ModifierGroup> groups) {
    double extra = 0;
    for (final group in groups) {
      final sel = _selected[group.id] ?? {};
      for (final opt in group.options) {
        if (sel.contains(opt.id)) extra += opt.priceAdjustment;
      }
    }
    return (widget.product.price + extra) * _quantity;
  }

  bool _validate(List<ModifierGroup> groups) {
    for (final group in groups) {
      if (group.isRequired) {
        final sel = _selected[group.id];
        if (sel == null || sel.isEmpty) return false;
      }
    }
    return true;
  }

  void _confirm(List<ModifierGroup> groups) {
    if (!_validate(groups)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາເລືອກຕົວເລືອກທີ່ຈຳເປັນ')),
      );
      return;
    }

    // Build modifier note from selections
    final modifierNotes = <String>[];
    for (final group in groups) {
      final sel = _selected[group.id] ?? {};
      for (final opt in group.options) {
        if (sel.contains(opt.id)) modifierNotes.add(opt.name);
      }
    }

    final fullNote = [
      if (modifierNotes.isNotEmpty) modifierNotes.join(', '),
      if (_noteCtrl.text.trim().isNotEmpty) _noteCtrl.text.trim(),
    ].join(' | ');

    final item = CartItem(
      productId: widget.product.id,
      productName: widget.product.name,
      unitPrice: widget.product.price +
          _calcModExtra(groups),
      quantity: _quantity,
      note: fullNote.isEmpty ? null : fullNote,
    );
    Navigator.pop(context, item);
  }

  double _calcModExtra(List<ModifierGroup> groups) {
    double extra = 0;
    for (final group in groups) {
      final sel = _selected[group.id] ?? {};
      for (final opt in group.options) {
        if (sel.contains(opt.id)) extra += opt.priceAdjustment;
      }
    }
    return extra;
  }

  @override
  Widget build(BuildContext context) {
    final modifiersAsync =
        ref.watch(productModifiersProvider(widget.product.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: modifiersAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildContent([], scrollCtrl),
            data: (groups) => _buildContent(groups, scrollCtrl),
          ),
        );
      },
    );
  }

  Widget _buildContent(
      List<ModifierGroup> groups, ScrollController scrollCtrl) {
    final total = _calcTotal(groups);
    return Column(
      children: [
        // Handle
        Center(
          child: Container(
            margin: EdgeInsets.only(top: 10.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ),

        // Header
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16.sp)),
                    Text(
                      '₭ ${_fmt.format(widget.product.price)}',
                      style: TextStyle(
                          color: AppColors.primary, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              // Quantity selector
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      iconSize: 18.sp,
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Text('$_quantity',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16.sp)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      iconSize: 18.sp,
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Modifier groups + note
        Expanded(
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.all(16.w),
            children: [
              ...groups.map((group) => _ModifierGroupSection(
                    group: group,
                    selected: _selected[group.id] ?? {},
                    onToggle: (opt) => _toggleOption(group, opt),
                  )),
              if (groups.isNotEmpty) SizedBox(height: 8.h),
              // Note field
              TextField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: 'ໝາຍເຫດ (ບໍ່ບັງຄັບ)',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),

        // Footer
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ລວມ',
                        style: TextStyle(
                            fontSize: 11.sp, color: Colors.black45)),
                    Text(
                      '₭ ${_fmt.format(total)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20.sp,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _confirm(groups),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('ເພີ່ມລົງຕະກ້າ'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: Size(160.w, 48.h),
                  textStyle: TextStyle(fontSize: 14.sp),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modifier group section
// ─────────────────────────────────────────────────────────────────────────────
class _ModifierGroupSection extends StatelessWidget {
  const _ModifierGroupSection({
    required this.group,
    required this.selected,
    required this.onToggle,
  });
  final ModifierGroup group;
  final Set<String> selected;
  final void Function(ModifierOption) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(group.name,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13.sp)),
            SizedBox(width: 8.w),
            if (group.isRequired)
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text('ຈຳເປັນ',
                    style: TextStyle(
                        fontSize: 9.sp, color: Colors.red.shade400)),
              ),
          ],
        ),
        SizedBox(height: 6.h),
        ...group.options.map((opt) => _OptionTile(
              option: opt,
              isSelected: selected.contains(opt.id),
              isMultiple: group.isMultiple,
              onToggle: () => onToggle(opt),
            )),
        SizedBox(height: 12.h),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.isMultiple,
    required this.onToggle,
  });
  final ModifierOption option;
  final bool isSelected;
  final bool isMultiple;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'th_TH');
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            isMultiple
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggle(),
                    activeColor: AppColors.primary,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )
                : Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : null,
                    size: 20.sp,
                  ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(option.name,
                  style: TextStyle(fontSize: 13.sp)),
            ),
            if (option.priceAdjustment != 0)
              Text(
                '${option.priceAdjustment > 0 ? '+' : ''}₭${fmt.format(option.priceAdjustment)}',
                style: TextStyle(
                    fontSize: 12.sp,
                    color: option.priceAdjustment > 0
                        ? Colors.green.shade600
                        : Colors.red.shade400,
                    fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}
