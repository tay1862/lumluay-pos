import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/products_repository.dart';
import '../../../../core/theme/app_theme.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          title: const Text('ສິນຄ້າ'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'ສິນຄ້າທັງໝົດ'),
              Tab(text: 'ໝວດໝູ່'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'ເພີ່ມສິນຄ້າ',
              onPressed: () => context.push('/products/new'),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _ProductsTab(),
            _CategoriesTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Products tab
// ─────────────────────────────────────────────────────────────────────────────
class _ProductsTab extends ConsumerStatefulWidget {
  const _ProductsTab();

  @override
  ConsumerState<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<_ProductsTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final selectedCat = ref.watch(productsCategoryFilterProvider);
    final fmt = NumberFormat('#,##0.00', 'th_TH');

    return Column(
      children: [
        // Search + category filter
        Container(
          color: Colors.white,
          padding: EdgeInsets.all(12.w),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ຄົ້ນຫາສິນຄ້າ...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref
                                .read(productsSearchProvider.notifier)
                                .state = '';
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                  contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                ),
                onChanged: (v) =>
                    ref.read(productsSearchProvider.notifier).state = v,
              ),
              SizedBox(height: 8.h),
              categoriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (cats) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'ທັງໝົດ',
                        selected: selectedCat == null,
                        onSelected: () => ref
                            .read(
                                productsCategoryFilterProvider.notifier)
                            .state = null,
                      ),
                      ...cats.map((cat) => _FilterChip(
                            label: cat.name,
                            selected: selectedCat == cat.id,
                            onSelected: () => ref
                                .read(productsCategoryFilterProvider
                                    .notifier)
                                .state = cat.id,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: productsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('ເກີດຂໍ້ຜິດພາດ: $e')),
            data: (products) {
              if (products.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 64, color: Colors.black26),
                      SizedBox(height: 12),
                      Text('ຍັງບໍ່ມີສິນຄ້າ',
                          style: TextStyle(color: Colors.black45)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(productsListProvider),
                child: GridView.builder(
                  padding: EdgeInsets.all(12.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 800 ? 4 : 2,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) =>
                      _ProductCard(product: products[i], fmt: fmt),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.fmt});
  final Product product;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/products/${product.id}/edit'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/placeholder
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(14.r)),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(product.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₭ ${fmt.format(product.basePrice)}',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp),
                        ),
                        if (!product.isActive)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text('ປິດ',
                                style: TextStyle(
                                    fontSize: 9.sp,
                                    color: Colors.grey.shade600)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: const Center(
        child: Icon(Icons.image_outlined,
            color: Colors.black26, size: 40),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories tab
// ─────────────────────────────────────────────────────────────────────────────
class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (cats) {
          if (cats.isEmpty) {
            return const Center(
              child: Text('ຍັງບໍ່ມີໝວດໝູ່',
                  style: TextStyle(color: Colors.black45)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(categoriesListProvider),
            child: ListView.separated(
              padding: EdgeInsets.all(12.w),
              itemCount: cats.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (ctx, i) {
                final cat = cats[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(cat.name.isNotEmpty ? cat.name[0] : '?',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp)),
                      ),
                    ),
                    title: Text(cat.name,
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('ລຳດັບ: ${cat.sortOrder}',
                        style: TextStyle(fontSize: 11.sp)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 20),
                          onPressed: () => _showCategoryDialog(
                              context, ref,
                              existing: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          onPressed: () =>
                              _deleteCategory(context, ref, cat),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref,
      {Category? existing}) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _CategoryDialog(existing: existing, ref: ref),
    );
  }

  void _deleteCategory(
      BuildContext context, WidgetRef ref, Category cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ຢືນຢັນການລົບ'),
        content: Text('ຕ້ອງການລົບໝວດໝູ່ "${cat.name}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ຍົກເລີກ')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ລົບ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(productsRepositoryProvider)
          .deleteCategory(cat.id);
      ref.invalidate(categoriesListProvider);
    }
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog({this.existing, required this.ref});
  final Category? existing;
  final WidgetRef ref;

  @override
  ConsumerState<_CategoryDialog> createState() =>
      _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _sortCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.existing?.name ?? '');
    _sortCtrl = TextEditingController(
        text: '${widget.existing?.sortOrder ?? 0}');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(productsRepositoryProvider);
      final sortOrder = int.tryParse(_sortCtrl.text) ?? 0;
      if (widget.existing != null) {
        await repo.updateCategory(
            widget.existing!.id, _nameCtrl.text.trim(), sortOrder);
      } else {
        await repo.createCategory(_nameCtrl.text.trim(), sortOrder);
      }
      ref.invalidate(categoriesListProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'ແກ້ໄຂໝວດໝູ່' : 'ເພີ່ມໝວດໝູ່'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'ຊື່'),
          ),
          TextField(
            controller: _sortCtrl,
            decoration: const InputDecoration(labelText: 'ລຳດັບ'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ')),
        FilledButton(
          onPressed: _loading ? null : _save,
          child:
              _loading ? const CircularProgressIndicator() : const Text('ບັນທຶກ'),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : Colors.black54,
          fontWeight:
              selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 11.sp,
        ),
        side: selected
            ? BorderSide(color: AppColors.primary.withValues(alpha: 0.3))
            : BorderSide.none,
      ),
    );
  }
}
