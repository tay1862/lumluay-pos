import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';

class CartItemCard extends ConsumerWidget {
  const CartItemCard({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat('#,##0.00', 'lo');
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      child: Row(
        children: [
          _QtyButton(
            icon: Icons.remove,
            semanticLabel: 'ຫຼຸດຈຳນວນ ${item.productName}',
            onTap: () => ref.read(cartProvider.notifier).removeItem(item.productId),
          ),
          SizedBox(
            width: 28.w,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
          ),
          _QtyButton(
            icon: Icons.add,
            semanticLabel: 'ເພີ່ມຈຳນວນ ${item.productName}',
            onTap: () => ref.read(cartProvider.notifier).addItem(
                  ProductItem(
                    id: item.productId,
                    name: item.productName,
                    price: item.unitPrice,
                    categoryId: '',
                  ),
                ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₭${currencyFmt.format(item.unitPrice)} / ອັນ',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
                if ((item.note ?? '').trim().isNotEmpty)
                  Text(
                    item.note!,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₭${currencyFmt.format(item.lineTotal)}',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
              Semantics(
                button: true,
                label: 'ລົບສິນຄ້າ ${item.productName} ອອກຈາກກະຕ່າ',
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: () => ref.read(cartProvider.notifier).deleteItem(item.productId),
                  child: SizedBox(
                    width: 32.w,
                    height: 32.h,
                    child: Icon(Icons.close, size: 14.sp, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick(); // 18.5.6
          onTap();
        },
        borderRadius: BorderRadius.circular(8.r),
        child: SizedBox(
          width: 48.w,
          height: 48.h,
          child: Center(
            child: Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDDDDD)),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Icon(icon, size: 14.sp),
            ),
          ),
        ),
      ),
    );
  }
}
