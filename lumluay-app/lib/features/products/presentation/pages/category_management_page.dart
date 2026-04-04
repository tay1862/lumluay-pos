import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/products_repository.dart';

class CategoryManagementPage extends ConsumerStatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  ConsumerState<CategoryManagementPage> createState() =>
      _CategoryManagementPageState();
}

class _CategoryManagementPageState
    extends ConsumerState<CategoryManagementPage> {
  List<Category>? _localList;
  bool _reordering = false;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการหมวดหมู่'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'เพิ่มหมวดหมู่',
            onPressed: () => _showCategoryDialog(context, null),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
        data: (categories) {
          _localList ??= List.from(categories);
          final list = _localList!;

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined,
                      size: 64.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  SizedBox(height: 12.h),
                  Text('ยังไม่มีหมวดหมู่',
                      style: theme.textTheme.titleMedium),
                  SizedBox(height: 4.h),
                  Text('แตะ + เพื่อเพิ่มหมวดหมู่',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Hint banner
              Container(
                width: double.infinity,
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Icon(Icons.drag_handle,
                        size: 16.sp,
                        color: theme.colorScheme.primary),
                    SizedBox(width: 8.w),
                    Text(
                      'ลากเพื่อเปลี่ยนลำดับ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (_reordering) ...[
                      const Spacer(),
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Reorderable list
              Expanded(
                child: ReorderableListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: list.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = list.removeAt(oldIndex);
                      list.insert(newIndex, item);
                    });
                    _saveOrder(list);
                  },
                  itemBuilder: (context, index) {
                    final cat = list[index];
                    return Card(
                      key: ValueKey(cat.id),
                      margin: EdgeInsets.only(bottom: 8.h),
                      child: ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.drag_handle,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4)),
                          ],
                        ),
                        title: Text(cat.name),
                        subtitle: Text('ลำดับ: ${cat.sortOrder}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _showCategoryDialog(context, cat),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: theme.colorScheme.error),
                              onPressed: () =>
                                  _confirmDelete(context, cat),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveOrder(List<Category> list) async {
    setState(() => _reordering = true);
    try {
      final repo = ref.read(productsRepositoryProvider);
      final items = list
          .asMap()
          .entries
          .map((e) => {'id': e.value.id, 'sortOrder': e.key})
          .toList();
      await repo.reorderCategories(items);
      ref.invalidate(categoriesListProvider);
      _localList = null; // reset so it picks up fresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกลำดับ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  void _showCategoryDialog(BuildContext context, Category? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(existing == null ? 'เพิ่มหมวดหมู่' : 'แก้ไขหมวดหมู่'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'ชื่อหมวดหมู่',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              await _saveCategory(existing, name);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory(Category? existing, String name) async {
    try {
      final repo = ref.read(productsRepositoryProvider);
      if (existing == null) {
        final sortOrder = (_localList?.length ?? 0);
        await repo.createCategory(name, sortOrder);
      } else {
        await repo.updateCategory(existing.id, name, existing.sortOrder);
      }
      _localList = null;
      ref.invalidate(categoriesListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, Category cat) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบหมวดหมู่'),
        content: Text(
            'ต้องการลบหมวดหมู่ "${cat.name}" ใช่ไหม?\n\nสินค้าในหมวดหมู่นี้จะยังคงอยู่ แต่ไม่มีหมวดหมู่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      try {
        await ref.read(productsRepositoryProvider).deleteCategory(cat.id);
        _localList = null;
        ref.invalidate(categoriesListProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    });
  }
}
