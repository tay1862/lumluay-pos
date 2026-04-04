import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/cart_provider.dart';
import 'cart_item_card.dart';
import 'member_lookup_dialog.dart';
import '../../../../shared/widgets/app_utils_widgets.dart';

class OrderCart extends ConsumerWidget {
  const OrderCart({super.key, required this.cart, required this.onCheckout});
  final CartState cart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(currencyCodeProvider).maybeWhen(
      data: (c) => c,
      orElse: () => 'THB',
    );
    String fmt(double v) => CurrencyText.format(v, currency: currencyCode);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            left: BorderSide(color: const Color(0xFFE0E0E0), width: 1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: const BoxDecoration(
              color: Color(0xFF1A7F64),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                SizedBox(width: 8.w),
                Text(
                  'รายการสั่ง',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (!cart.isEmpty)
                  TextButton(
                    onPressed: () =>
                        ref.read(cartProvider.notifier).clear(),
                    child: Text('ล้าง',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12.sp)),
                  ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
            child: Row(
              children: [
                Expanded(
                  child: _OrderTypeChip(
                    label: 'Dine-in',
                    selected: cart.orderType == 'dine_in',
                    onTap: () => ref.read(cartProvider.notifier).setOrderType('dine_in'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _OrderTypeChip(
                    label: 'Takeaway',
                    selected: cart.orderType == 'takeaway',
                    onTap: () => ref.read(cartProvider.notifier).setOrderType('takeaway'),
                  ),
                ),
              ],
            ),
          ),

          // Member row
          _MemberRow(cart: cart),

          // Cart items
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 48.sp, color: Colors.grey[300]),
                        SizedBox(height: 8.h),
                        Text('ยังไม่มีรายการ',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 14.sp)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 14),
                    itemBuilder: (context, i) {
                      final item = cart.items[i];
                      return CartItemCard(item: item);
                    },
                  ),
          ),

          // Totals
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              border: Border(
                  top: BorderSide(color: const Color(0xFFE0E0E0))),
            ),
            child: Column(
              children: [
                _TotalRow(
                    label: 'รวมก่อนส่วนลด',
                    value: fmt(cart.subtotal)),
                if (cart.discountAmount > 0)
                  _TotalRow(
                    label: 'ส่วนลด',
                    value: '-${fmt(cart.discountAmount)}',
                    valueColor: Colors.red,
                  ),
                const Divider(height: 12),
                _TotalRow(
                  label: 'ยอดรวม',
                  value: fmt(cart.total),
                  isTotal: true,
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: cart.isEmpty ? null : onCheckout,
                    icon: const Icon(Icons.payment),
                    label: Text(
                        'ชำระเงิน (${cart.itemCount} รายการ)',
                        style: TextStyle(fontSize: 15.sp)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTypeChip extends StatelessWidget {
  const _OrderTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.12) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected ? primary : const Color(0xFFE4E7EC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? primary : Colors.black87,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 14.sp : 12.sp,
                  fontWeight:
                      isTotal ? FontWeight.w700 : FontWeight.normal,
                  color: isTotal ? Colors.black87 : Colors.grey[600])),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 16.sp : 13.sp,
                  fontWeight: FontWeight.w700,
                  color: valueColor ??
                      (isTotal
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Member row (12.2.5)
// ─────────────────────────────────────────────────────────────────────────────
class _MemberRow extends ConsumerWidget {
  const _MemberRow({required this.cart});
  final CartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMember = cart.memberId != null;
    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => const MemberLookupDialog(),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: hasMember ? Colors.green[50] : const Color(0xFFF9FAFB),
          border: Border(
            top: BorderSide(color: const Color(0xFFE0E0E0)),
            bottom: BorderSide(color: const Color(0xFFE0E0E0)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasMember ? Icons.person : Icons.person_add_outlined,
              size: 16.sp,
              color: hasMember ? Colors.green[700] : Colors.black38,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                hasMember ? (cart.memberName ?? cart.memberId!) : 'เพิ่มสมาชิก',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: hasMember ? Colors.green[800] : Colors.black38,
                  fontWeight: hasMember ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (hasMember)
              GestureDetector(
                onTap: () => ref.read(cartProvider.notifier).clearMember(),
                child: Icon(Icons.close, size: 15.sp, color: Colors.black38),
              )
            else
              Icon(Icons.chevron_right, size: 16.sp, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
