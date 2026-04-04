import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/cart_provider.dart';

class QuickKeysBar extends StatelessWidget {
  const QuickKeysBar({
    super.key,
    required this.products,
    required this.onTapProduct,
  });

  final List<ProductItem> products;
  final Future<void> Function(ProductItem product, Offset tapOrigin)
      onTapProduct;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final quick = products.take(8).toList();
    return Container(
      height: 44.h,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quick.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final product = quick[index];
          return Builder(
            builder: (buttonContext) => OutlinedButton.icon(
              onPressed: product.isAvailable
                  ? () {
                      final box = buttonContext.findRenderObject() as RenderBox?;
                      final tapOrigin = box != null
                          ? box.localToGlobal(
                              Offset(box.size.width / 2, box.size.height / 2),
                            )
                          : Offset.zero;
                      onTapProduct(product, tapOrigin);
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              ),
              icon: const Icon(Icons.flash_on, size: 14),
              label: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          );
        },
      ),
    );
  }
}
