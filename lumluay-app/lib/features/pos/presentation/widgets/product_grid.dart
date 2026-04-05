import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.onAddRequested,
  });

  final List<ProductItem> products;
  final Future<void> Function(ProductItem product, Offset tapOrigin)
      onAddRequested;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 8.h),
            Text('ບໍ່ມີສິນຄ້າ',
                style: TextStyle(color: Colors.grey[500], fontSize: 14.sp)),
          ],
        ),
      );
    }

    final currencyFmt = NumberFormat('#,##0.00', 'lo');

    return GridView.builder(
      padding: EdgeInsets.all(12.w),
      cacheExtent: 800,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160.w,
        mainAxisExtent: 170.h,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final product = products[i];
        final renderObject = context.findRenderObject();
        final box = renderObject is RenderBox ? renderObject : null;
        final tapOrigin = box != null
            ? box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2))
            : Offset.zero;
        return _ProductCard(
          product: product,
          priceLabel: '₭${currencyFmt.format(product.price)}',
          onTap: product.isAvailable
              ? () => onAddRequested(product, tapOrigin)
              : null,
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.priceLabel,
    this.onTap,
  });
  final ProductItem product;
  final String priceLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unavailable = onTap == null;
    return Semantics(
      button: true,
      enabled: !unavailable,
      label: '${product.name} ລາຄາ $priceLabel',
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact(); // 18.5.6
                  onTap!();
                },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image area
              Expanded(
                child: RepaintBoundary(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      product.imageUrl != null
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.low,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                      if (unavailable)
                        Container(
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: Text(
                            'ໝົດ',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Info area
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      priceLabel,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFEEEEEE),
        child: Icon(Icons.fastfood_outlined,
            size: 36, color: Colors.grey[400]),
      );
}
