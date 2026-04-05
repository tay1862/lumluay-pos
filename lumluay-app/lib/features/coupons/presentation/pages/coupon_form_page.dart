import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../data/coupons_repository.dart';

class CouponFormPage extends ConsumerStatefulWidget {
  /// When [coupon] is null, creates a new coupon; otherwise edits it.
  final Coupon? coupon;

  const CouponFormPage({super.key, this.coupon});

  @override
  ConsumerState<CouponFormPage> createState() => _CouponFormPageState();
}

class _CouponFormPageState extends ConsumerState<CouponFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _minOrderCtrl;
  late final TextEditingController _maxDiscountCtrl;
  late final TextEditingController _usageLimitCtrl;

  CouponType _type = CouponType.fixed;
  bool _isActive = true;
  DateTime? _startsAt;
  DateTime? _expiresAt;
  bool _saving = false;

  bool get _isEdit => widget.coupon != null;

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _codeCtrl = TextEditingController(text: c?.code ?? '');
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _valueCtrl = TextEditingController(
        text: c != null ? c.value.toString() : '');
    _minOrderCtrl = TextEditingController(
        text: c?.minOrderAmount?.toString() ?? '');
    _maxDiscountCtrl = TextEditingController(
        text: c?.maxDiscountAmount?.toString() ?? '');
    _usageLimitCtrl = TextEditingController(
        text: c?.usageLimit?.toString() ?? '');
    if (c != null) {
      _type = c.type;
      _isActive = c.isActive;
      _startsAt = c.startsAt;
      _expiresAt = c.expiresAt;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    _minOrderCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _usageLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'code': _codeCtrl.text.trim().toUpperCase(),
      'name': _nameCtrl.text.trim(),
      if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      'type': _type == CouponType.percent
          ? 'percent'
          : _type == CouponType.freeItem
              ? 'free_item'
              : 'fixed',
      'value': double.parse(_valueCtrl.text.trim()),
      if (_minOrderCtrl.text.trim().isNotEmpty)
        'minOrderAmount': double.parse(_minOrderCtrl.text.trim()),
      if (_maxDiscountCtrl.text.trim().isNotEmpty)
        'maxDiscountAmount': double.parse(_maxDiscountCtrl.text.trim()),
      if (_usageLimitCtrl.text.trim().isNotEmpty)
        'usageLimit': int.parse(_usageLimitCtrl.text.trim()),
      'isActive': _isActive,
      if (_startsAt != null) 'startsAt': _startsAt!.toIso8601String(),
      if (_expiresAt != null) 'expiresAt': _expiresAt!.toIso8601String(),
    };

    try {
      final repo = ref.read(couponsRepositoryProvider);
      if (_isEdit) {
        await repo.updateCoupon(widget.coupon!.id, data);
      } else {
        await repo.createCoupon(data);
      }
      ref.invalidate(couponsListProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ບັນທຶກບໍ່ສຳເລັດ: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(bool isExpiry) async {
    final initial = isExpiry
        ? (_expiresAt ?? DateTime.now().add(const Duration(days: 30)))
        : (_startsAt ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isExpiry) {
        _expiresAt = picked;
      } else {
        _startsAt = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'ແກ້ໄຂຄູປອງ' : 'ເພີ່ມຄູປອງ'),
        actions: [
          if (_saving)
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            TextButton(
              onPressed: _save,
              child: const Text('ບັນທຶກ'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // ─ Code ──────────────────────────────────────────────────────
            TextFormField(
              controller: _codeCtrl,
              enabled: !_isEdit,
              decoration: const InputDecoration(
                  labelText: 'ລະຫັດຄູປອງ *',
                  hintText: 'SUMMER20',
                  helperText: 'ລະຫັດຈະຖືກແປງເປັນຕົວພິມໃຫຍ່'),
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'ກະລຸນາກລອກລະຫັດຄູປອງ' : null,
            ),
            SizedBox(height: 12.h),

            // ─ Name ──────────────────────────────────────────────────────
            TextFormField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'ຊື່ຄູປອງ *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'ກະລຸນາກລອກຊື່ຄູປອງ' : null,
            ),
            SizedBox(height: 12.h),

            // ─ Description ───────────────────────────────────────────────
            TextFormField(
              controller: _descCtrl,
              decoration:
                  const InputDecoration(labelText: 'ລາຍລະອຽດ'),
              maxLines: 2,
            ),
            SizedBox(height: 16.h),

            // ─ Type ──────────────────────────────────────────────────────
            Text('ປະເພດສ່ວນຫຼຸດ',
                style: theme.textTheme.labelLarge),
            SizedBox(height: 8.h),
            SegmentedButton<CouponType>(
              segments: const [
                ButtonSegment(
                    value: CouponType.fixed, label: Text('ຈຳນວນເງິນ')),
                ButtonSegment(
                    value: CouponType.percent, label: Text('ເປີເຊັນ')),
                ButtonSegment(
                    value: CouponType.freeItem, label: Text('ຂອງຟຣີ')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            SizedBox(height: 12.h),

            // ─ Value ─────────────────────────────────────────────────────
            TextFormField(
              controller: _valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _type == CouponType.percent
                    ? 'ສ່ວນຫຼຸດ (%) *'
                    : 'ສ່ວນຫຼຸດ (₭) *',
                prefixText: _type == CouponType.percent ? null : '₭',
                suffixText: _type == CouponType.percent ? '%' : null,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'ກລອກມູນຄ່າສ່ວນຫຼຸດ';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'ຕ້ອງເປັນຕົວເລກຫຼາຍກວ່າ 0';
                if (_type == CouponType.percent && n > 100) {
                  return 'ເປີເຊັນຕ້ອງບໍ່ເກີນ 100';
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),

            // ─ Conditions ────────────────────────────────────────────────
            Text('ເງື່ອນໄຂ', style: theme.textTheme.labelLarge),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minOrderCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'ຍອດຂັ້ນຕໍ່ຳ (₭)',
                        prefixText: '₭'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'ຕົວເລກບໍ່ຖືກຕ້ອງ';
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextFormField(
                    controller: _maxDiscountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'ສ່ວນຫຼຸດສູງສຸດ (₭)',
                        prefixText: '₭'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'ຕົວເລກບໍ່ຖືກຕ້ອງ';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextFormField(
              controller: _usageLimitCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'ຈຳນວນຄັ້ງທີ່ໃຊ້ໄດ້'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v.trim());
                if (n == null || n < 1) return 'ຕ້ອງເປັນຈຳນວນເຕັມຫຼາຍກວ່າ 0';
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // ─ Dates ─────────────────────────────────────────────────────
            Text('ລະຍະເວລາ', style: theme.textTheme.labelLarge),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'ເລີ່ມຕົ້ນ',
                    value: _startsAt,
                    onTap: () => _pickDate(false),
                    onClear: () => setState(() => _startsAt = null),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _DateField(
                    label: 'ໝົດອາຍຸ',
                    value: _expiresAt,
                    onTap: () => _pickDate(true),
                    onClear: () => setState(() => _expiresAt = null),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // ─ Active toggle ─────────────────────────────────────────────
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('ເປີດໃຊ້ງານ'),
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: 24.h),

            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEdit ? 'ບັນທຶກການແກ້ໄຂ' : 'ສ້າງຄູປອງ'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date Field ───────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          value != null
              ? '${value!.day}/${value!.month}/${value!.year}'
              : '-',
          style: TextStyle(
              fontSize: 14.sp,
              color: value != null ? null : Colors.black38),
        ),
      ),
    );
  }
}
