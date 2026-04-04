import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/products_repository.dart';
import '../../../../core/theme/app_theme.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.productId});
  final String? productId;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _selectedCategoryId;
  String _productType = 'simple';
  bool _isActive = true;
  bool _loading = false;
  bool _initialLoading = false;
  final List<_VariantDraft> _variants = [];
  final Set<String> _removedVariantIds = {};
  final Map<String, _VariantSnapshot> _originalVariants = {};

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _initialLoading = true);
    try {
      final product = await ref
          .read(productsRepositoryProvider)
          .getProduct(widget.productId!);
      _nameCtrl.text = product.name;
      _priceCtrl.text = product.basePrice.toStringAsFixed(2);
      _skuCtrl.text = product.sku ?? '';
      _barcodeCtrl.text = (product.toJson()['barcode'] as String?) ?? '';
      _selectedCategoryId = product.category?.id;
      _productType = product.productType;
      _isActive = product.isActive;
      _variants
        ..clear()
        ..addAll(product.variants.map((v) => _VariantDraft.fromVariant(v)));
      _originalVariants
        ..clear()
        ..addEntries(product.variants.map((v) => MapEntry(
              v.id,
              _VariantSnapshot(
                name: v.name,
                price: v.price,
                sku: v.sku,
              ),
            )));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('โหลดข้อมูลล้มเหลว: $e')));
      }
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  @override
  void dispose() {
    for (final v in _variants) {
      v.dispose();
    }
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_productType == 'variant') {
      final hasValidVariant = _variants.any((v) {
        final name = v.nameCtrl.text.trim();
        final price = double.tryParse(v.priceCtrl.text.trim());
        return name.isNotEmpty && price != null && price >= 0;
      });
      if (!hasValidVariant) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเพิ่มตัวเลือกสินค้าอย่างน้อย 1 รายการ')),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(productsRepositoryProvider);
      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'basePrice':
            double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0,
        'productType': _productType,
        'isActive': _isActive,
        if (_skuCtrl.text.trim().isNotEmpty) 'sku': _skuCtrl.text.trim(),
        if (_barcodeCtrl.text.trim().isNotEmpty) 'barcode': _barcodeCtrl.text.trim(),
        if (_selectedCategoryId != null) 'categoryId': _selectedCategoryId,
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      };
      late final String productId;
      if (_isEdit) {
        await repo.updateProduct(widget.productId!, body);
        productId = widget.productId!;
      } else {
        final created = await repo.createProduct(body);
        productId = created.id;
      }

      if (_productType == 'variant') {
        await _syncVariants(repo, productId);
      } else if (_isEdit && _originalVariants.isNotEmpty) {
        for (final id in _originalVariants.keys) {
          await repo.removeVariant(productId, id);
        }
      }

      ref.invalidate(productsListProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('บันทึกล้มเหลว: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncVariants(ProductsRepository repo, String productId) async {
    for (final id in _removedVariantIds) {
      await repo.removeVariant(productId, id);
    }

    for (final v in _variants) {
      final name = v.nameCtrl.text.trim();
      final price = double.tryParse(v.priceCtrl.text.trim());
      final sku = v.skuCtrl.text.trim();
      if (name.isEmpty || price == null || price < 0) continue;

      final payload = <String, dynamic>{
        'name': name,
        'price': price,
        if (sku.isNotEmpty) 'sku': sku,
      };

      if (v.id == null) {
        await repo.addVariant(productId, payload);
        continue;
      }

      final original = _originalVariants[v.id!];
      final changed = original == null ||
          original.name != name ||
          original.price != price ||
          (original.sku ?? '') != sku;

      if (changed) {
        await repo.removeVariant(productId, v.id!);
        await repo.addVariant(productId, payload);
      }
    }
  }

  void _addVariant() {
    setState(() {
      _variants.add(_VariantDraft.empty());
    });
  }

  void _removeVariant(_VariantDraft draft) {
    setState(() {
      if (draft.id != null) {
        _removedVariantIds.add(draft.id!);
      }
      _variants.remove(draft);
      draft.dispose();
    });
  }

  // 17.2.5 — camera barcode scan fills the barcode field
  void _openBarcodeScanner() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.50,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text('สแกน Barcode',
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final code = capture.barcodes.firstOrNull?.rawValue;
                  if (code != null && code.isNotEmpty) {
                    Navigator.of(context).pop();
                    setState(() => _barcodeCtrl.text = code);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบสินค้า "${_nameCtrl.text}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref
            .read(productsRepositoryProvider)
            .deleteProduct(widget.productId!);
        ref.invalidate(productsListProvider);
        if (mounted) context.go('/products');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('ลบล้มเหลว: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'แก้ไขสินค้า' : 'เพิ่มสินค้า'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text('บันทึก',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(16.w),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _SectionHeader('ข้อมูลทั่วไป'),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                              labelText: 'ชื่อสินค้า *',
                              border: OutlineInputBorder()),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'กรุณากรอกชื่อสินค้า'
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _priceCtrl,
                          decoration: const InputDecoration(
                              labelText: 'ราคาตั้งต้น (฿) *',
                              border: OutlineInputBorder(),
                              prefixText: '฿ '),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'กรุณากรอกราคา';
                            if (double.tryParse(
                                    v.replaceAll(',', '')) ==
                                null) { return 'ราคาไม่ถูกต้อง'; }
                            return null;
                          },
                        ),
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _skuCtrl,
                          decoration: const InputDecoration(
                              labelText: 'รหัสสินค้า (SKU)',
                              border: OutlineInputBorder()),
                        ),
                        SizedBox(height: 12.h),
                        // 17.2.5 Barcode field with camera scan
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _barcodeCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Barcode',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: IconButton.filledTonal(
                                tooltip: 'สแกน Barcode',
                                icon: const Icon(Icons.qr_code_scanner),
                                onPressed: _openBarcodeScanner,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                              labelText: 'คำอธิบาย',
                              border: OutlineInputBorder()),
                          maxLines: 3,
                        ),
                        SizedBox(height: 20.h),

                        _SectionHeader('หมวดหมู่และประเภท'),
                        SizedBox(height: 8.h),
                        categoriesAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (cats) => DropdownButtonFormField<String?>(
                            initialValue: _selectedCategoryId,
                            decoration: const InputDecoration(
                                labelText: 'หมวดหมู่',
                                border: OutlineInputBorder()),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('ไม่ระบุ')),
                              ...cats.map((c) => DropdownMenuItem(
                                  value: c.id, child: Text(c.name))),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedCategoryId = v),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        DropdownButtonFormField<String>(
                          initialValue: _productType,
                          decoration: const InputDecoration(
                              labelText: 'ประเภทสินค้า',
                              border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(
                                value: 'simple', child: Text('ธรรมดา')),
                            DropdownMenuItem(
                                value: 'variant',
                                child: Text('มีตัวเลือก')),
                            DropdownMenuItem(
                                value: 'combo', child: Text('คอมโบ')),
                          ],
                          onChanged: (v) =>
                              setState(() => _productType = v ?? 'simple'),
                        ),
                        if (_productType == 'variant') ...[
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Text(
                                'ตัวเลือกสินค้า (Variant)',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: _addVariant,
                                icon: const Icon(Icons.add),
                                label: const Text('เพิ่มตัวเลือก'),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          if (_variants.isEmpty)
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Text(
                                'ยังไม่มีตัวเลือกสินค้า กด "เพิ่มตัวเลือก" เพื่อสร้างเช่น S/M/L',
                                style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                              ),
                            ),
                          ..._variants.map((v) => Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: Container(
                                  padding: EdgeInsets.all(10.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: v.nameCtrl,
                                              decoration: const InputDecoration(
                                                labelText: 'ชื่อตัวเลือก *',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          IconButton(
                                            onPressed: () => _removeVariant(v),
                                            icon: const Icon(Icons.delete_outline),
                                            color: Colors.red,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: v.priceCtrl,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(
                                                labelText: 'ราคา *',
                                                prefixText: '฿ ',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: TextFormField(
                                              controller: v.skuCtrl,
                                              decoration: const InputDecoration(
                                                labelText: 'SKU',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                        SizedBox(height: 20.h),

                        _SectionHeader('สถานะ'),
                        SizedBox(height: 8.h),
                        SwitchListTile.adaptive(
                          title: Text('เปิดขาย',
                              style: TextStyle(fontSize: 14.sp)),
                          subtitle: Text(
                            _isActive ? 'สินค้านี้แสดงในหน้าขาย' : 'ซ่อนจากหน้าขาย',
                            style: TextStyle(fontSize: 11.sp),
                          ),
                          value: _isActive,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => _isActive = v),
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                        SizedBox(height: 40.h),

                        FilledButton(
                          onPressed: _loading ? null : _save,
                          style: FilledButton.styleFrom(
                              minimumSize: Size(double.infinity, 48.h),
                              backgroundColor: AppColors.primary),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  _isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มสินค้า',
                                  style: TextStyle(fontSize: 15.sp)),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black45,
          letterSpacing: 0.5),
    );
  }
}

class _VariantDraft {
  _VariantDraft({
    required this.id,
    required this.nameCtrl,
    required this.priceCtrl,
    required this.skuCtrl,
  });

  final String? id;
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController skuCtrl;

  factory _VariantDraft.empty() => _VariantDraft(
        id: null,
        nameCtrl: TextEditingController(),
        priceCtrl: TextEditingController(),
        skuCtrl: TextEditingController(),
      );

  factory _VariantDraft.fromVariant(ProductVariant v) => _VariantDraft(
        id: v.id,
        nameCtrl: TextEditingController(text: v.name),
        priceCtrl: TextEditingController(text: v.price.toStringAsFixed(2)),
        skuCtrl: TextEditingController(text: v.sku ?? ''),
      );

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    skuCtrl.dispose();
  }
}

class _VariantSnapshot {
  const _VariantSnapshot({
    required this.name,
    required this.price,
    required this.sku,
  });

  final String name;
  final double price;
  final String? sku;
}
