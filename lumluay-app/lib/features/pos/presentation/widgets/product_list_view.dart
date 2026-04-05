import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';

class ProductListView extends StatelessWidget {
  const ProductListView({
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
      return const Center(child: Text('ບໍ່ມີສິນຄ້າ'));
    }

    final money = NumberFormat('#,##0.00', 'lo');

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = products[index];
        final box = context.findRenderObject() as RenderBox?;
        final tapOrigin = box != null
            ? box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2))
            : Offset.zero;
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 20.r,
            backgroundColor: const Color(0xFFF0F2F5),
            backgroundImage:
                product.imageUrl != null ? NetworkImage(product.imageUrl!) : null,
            child: product.imageUrl == null
                ? const Icon(Icons.fastfood_outlined, size: 18)
                : null,
          ),
          title: Text(
            product.name,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '₭${money.format(product.price)}',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle),
            color: Theme.of(context).colorScheme.primary,
            onPressed: product.isAvailable
                ? () => onAddRequested(product, tapOrigin)
                : null,
          ),
          onTap: product.isAvailable
              ? () => onAddRequested(product, tapOrigin)
              : null,
        );
      },
    );
  }
}
