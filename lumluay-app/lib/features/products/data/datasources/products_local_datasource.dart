import 'package:drift/drift.dart' show Value;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/products_dao.dart';
import '../models/product_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 16.2.9 — Drift-backed local datasource (replaces in-memory Map)
// ─────────────────────────────────────────────────────────────────────────────

class ProductsLocalDataSource {
  ProductsLocalDataSource(this._dao);

  final ProductsDao _dao;

  // ── Conversion helpers ────────────────────────────────────────────────────

  Product _rowToProduct(LocalProductRow r, List<LocalCategoryRow> cats) {
    final cat = r.categoryId != null
        ? cats.where((c) => c.id == r.categoryId).map((c) => Category(
              id: c.id,
              name: c.name,
              sortOrder: c.sortOrder,
            )).firstOrNull
        : null;
    return Product(
      id: r.id,
      name: r.name,
      basePrice: r.basePrice,
      sku: r.sku,
      imageUrl: r.imageUrl,
      productType: r.productType,
      isActive: r.isActive,
      category: cat,
      stock: null,
      variants: const [],
      modifierGroups: const [],
    );
  }

  Category _rowToCategory(LocalCategoryRow r) =>
      Category(id: r.id, name: r.name, sortOrder: r.sortOrder);

  LocalProductsCompanion _productToCompanion(Product p) =>
      LocalProductsCompanion.insert(
        id: p.id,
        categoryId: Value(p.category?.id),
        name: p.name,
        basePrice: Value(p.basePrice),
        sku: Value(p.sku),
        imageUrl: Value(p.imageUrl),
        productType: Value(p.productType),
        isActive: Value(p.isActive),
        updatedAt: DateTime.now().toIso8601String(),
      );

  LocalCategoriesCompanion _categoryToCompanion(Category c) =>
      LocalCategoriesCompanion.insert(
        id: c.id,
        name: c.name,
        sortOrder: Value(c.sortOrder),
        updatedAt: DateTime.now().toIso8601String(),
      );

  // ── Products ──────────────────────────────────────────────────────────────

  Future<void> cacheProducts(List<Product> products) async {
    await _dao.deleteAllProducts();
    for (final p in products) {
      await _dao.upsertProduct(_productToCompanion(p));
    }
  }

  Future<List<Product>> getProducts({String? categoryId, String? search}) async {
    final rows = await _dao.getProducts(categoryId: categoryId, search: search);
    final catRows = await _dao.getAllCategories();
    return rows.map((r) => _rowToProduct(r, catRows)).toList();
  }

  Future<void> upsertProduct(Product product) async {
    await _dao.upsertProduct(_productToCompanion(product));
  }

  Future<Product?> getProduct(String id) async {
    final row = await _dao.getProduct(id);
    if (row == null) return null;
    final catRows = await _dao.getAllCategories();
    return _rowToProduct(row, catRows);
  }

  Future<void> removeProduct(String id) => _dao.deleteProduct(id);

  Future<Product?> findByBarcode(String code) async {
    final row = await _dao.findByBarcode(code);
    if (row == null) return null;
    final catRows = await _dao.getAllCategories();
    return _rowToProduct(row, catRows);
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<void> cacheCategories(List<Category> categories) async {
    await _dao.deleteAllCategories();
    for (final c in categories) {
      await _dao.upsertCategory(_categoryToCompanion(c));
    }
  }

  Future<List<Category>> getCategories() async {
    final rows = await _dao.getAllCategories();
    return rows.map(_rowToCategory).toList();
  }

  Future<void> upsertCategory(Category category) =>
      _dao.upsertCategory(_categoryToCompanion(category));

  Future<void> removeCategory(String id) => _dao.deleteCategory(id);

  Future<void> reorderCategories(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      final id = item['id'] as String;
      final sortOrder = item['sortOrder'] as int;
      final existing = await _dao.getProduct(id);
      if (existing == null) continue;
      await _dao.upsertCategory(
        LocalCategoriesCompanion(
          id: Value(id),
          sortOrder: Value(sortOrder),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );
    }
  }
}
