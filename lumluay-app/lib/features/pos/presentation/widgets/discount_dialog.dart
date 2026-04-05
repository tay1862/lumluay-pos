import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widgets/numpad_widget.dart';
import '../../../../shared/widgets/app_buttons.dart';
import '../../../../features/coupons/data/coupons_repository.dart'
    show couponsRepositoryProvider, ValidateCouponResult;

enum DiscountType { percent, amount, coupon }

class DiscountResult {
  final DiscountType type;
  final double value;
  final String? couponCode;

  const DiscountResult({
    required this.type,
    required this.value,
    this.couponCode,
  });
}

class DiscountDialog extends ConsumerStatefulWidget {
  final double orderTotal;
  final DiscountResult? initial;

  const DiscountDialog({
    super.key,
    required this.orderTotal,
    this.initial,
  });

  static Future<DiscountResult?> show(
    BuildContext context, {
    required double orderTotal,
    DiscountResult? initial,
  }) =>
      showDialog<DiscountResult>(
        context: context,
        builder: (_) => DiscountDialog(
          orderTotal: orderTotal,
          initial: initial,
        ),
      );

  @override
  ConsumerState<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends ConsumerState<DiscountDialog> {
  DiscountType _type = DiscountType.percent;
  String _numpadValue = '';
  final _couponController = TextEditingController();

  // coupon validation state
  ValidateCouponResult? _couponResult;
  String? _couponError;
  bool _validating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _type = widget.initial!.type;
      if (_type == DiscountType.coupon) {
        _couponController.text = widget.initial!.couponCode ?? '';
      } else if (widget.initial!.value > 0) {
        _numpadValue = widget.initial!.value
            .toStringAsFixed(widget.initial!.value.truncateToDouble() ==
                    widget.initial!.value
                ? 0
                : 2)
            .replaceAll(RegExp(r'\.?0+$'), '');
      }
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  double get _parsedValue => double.tryParse(_numpadValue) ?? 0;

  double get _discountAmount {
    if (_type == DiscountType.percent) {
      return widget.orderTotal * (_parsedValue / 100);
    }
    return _parsedValue;
  }

  bool get _isValid {
    if (_type == DiscountType.coupon) {
      return _couponResult != null;
    }
    if (_parsedValue <= 0) return false;
    if (_type == DiscountType.percent && _parsedValue > 100) return false;
    if (_type == DiscountType.amount && _parsedValue > widget.orderTotal) {
      return false;
    }
    return true;
  }

  Future<void> _validateCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _validating = true;
      _couponError = null;
      _couponResult = null;
    });
    try {
      final repo = ref.read(couponsRepositoryProvider);
      final result =
          await repo.validateCoupon(code, widget.orderTotal);
      setState(() {
        _couponResult = result;
        _couponError = null;
      });
    } catch (e) {
      setState(() {
        _couponError = e.toString().replaceFirst('Exception: ', '');
        _couponResult = null;
      });
    } finally {
      setState(() => _validating = false);
    }
  }

  void _confirm() {
    if (!_isValid) return;
    DiscountResult result;
    if (_type == DiscountType.coupon) {
      result = DiscountResult(
        type: DiscountType.coupon,
        value: _couponResult!.discountAmount,
        couponCode: _couponController.text.trim(),
      );
    } else {
      result = DiscountResult(type: _type, value: _parsedValue);
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400.w),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ສ່ວນຫຼຸດ',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),

              // Type selector
              SegmentedButton<DiscountType>(
                segments: const [
                  ButtonSegment(
                    value: DiscountType.percent,
                    label: Text('ເປີເຊັນ'),
                    icon: Icon(Icons.percent),
                  ),
                  ButtonSegment(
                    value: DiscountType.amount,
                    label: Text('ຈຳນວນເງິນ'),
                    icon: Icon(Icons.money),
                  ),
                  ButtonSegment(
                    value: DiscountType.coupon,
                    label: Text('ຄູປອງ'),
                    icon: Icon(Icons.confirmation_number_outlined),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _numpadValue = '';
                  _couponController.clear();
                  _couponResult = null;
                  _couponError = null;
                }),
              ),
              SizedBox(height: 16.h),

              if (_type == DiscountType.coupon) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) => setState(() {
                          _couponResult = null;
                          _couponError = null;
                        }),
                        onSubmitted: (_) => _validateCoupon(),
                        decoration: InputDecoration(
                          labelText: 'ລະຫັດຄູປອງ',
                          prefixIcon: const Icon(
                              Icons.confirmation_number_outlined),
                          errorText: _couponError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    SizedBox(
                      height: 56.h,
                      child: FilledButton(
                        onPressed: _validating ? null : _validateCoupon,
                        child: _validating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Text('ກວດສອບ'),
                      ),
                    ),
                  ],
                ),
                if (_couponResult != null) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 18),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _couponResult!.coupon.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'ສ່ວນຫຼຸດ: ₭${_couponResult!.discountAmount.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // Display value
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _numpadValue.isEmpty ? '0' : _numpadValue,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _type == DiscountType.percent ? '%' : '₭',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: theme.colorScheme.secondary),
                      ),
                    ],
                  ),
                ),
                if (_parsedValue > 0) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'ສ່ວນຫຼຸດ: ₭${_discountAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 12.h),
                NumpadWidget(
                  value: _numpadValue,
                  onChanged: (v) => setState(() => _numpadValue = v),
                  showDecimal: _type == DiscountType.amount,
                  maxDecimalPlaces: 2,
                ),
              ],

              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'ຍົກເລີກ',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'ຢືນຢັນ',
                      onPressed: _isValid ? _confirm : null,
                      icon: Icons.check,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
