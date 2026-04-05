import 'package:drift/drift.dart';
import '../app_database.dart';

part 'products_dao.g.dart';

/// 16.2.2 — Local Product Cache DAO
@DriftAccessor(tables: [LocalProducts, LocalCategories])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<List<LocalCategoryRow>> getAllCategories() =>
      (select(localCategories)
            ..where((c) => c.isActive.equals(true))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();

  Stream<List<LocalCategoryRow>> watchAllCategories() =>
      (select(localCategories)
            ..where((c) => c.isActive.equals(true))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch();

  Future<void> upsertCategory(LocalCategoriesCompanion cat) =>
      into(localCategories).insertOnConflictUpdate(cat);

  Future<void> deleteCategory(String id) =>
      (delete(localCategories)..where((c) => c.id.equals(id))).go();

  Future<void> deleteAllCategories() => delete(localCategories).go();

  // ── Products ───────────────────────────────────────────────────────────────

  Future<List<LocalProductRow>> getProducts({
    String? categoryId,
    String? search,
  }) {
    final query = select(localProducts)
      ..where((p) => p.isActive.equals(true))
      ..orderBy([
        (p) => OrderingTerm.asc(p.sortOrder),
        (p) => OrderingTerm.asc(p.name),
      ]);
    if (categoryId != null && categoryId.isNotEmpty) {
      query.where((p) => p.categoryId.equals(categoryId));
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = '%${search.trim().toLowerCase()}%';
      query.where((p) => p.name.lower().like(q) | p.sku.lower().like(q));
    }
    return query.get();
  }

  Stream<List<LocalProductRow>> watchProducts({String? categoryId}) {
    final query = select(localProducts)
      ..where((p) => p.isActive.equals(true))
      ..orderBy([
        (p) => OrderingTerm.asc(p.sortOrder),
        (p) => OrderingTerm.asc(p.name),
      ]);
    if (categoryId != null && categoryId.isNotEmpty) {
      query.where((p) => p.categoryId.equals(categoryId));
    }
    return query.watch();
  }

  Future<LocalProductRow?> getProduct(String id) =>
      (select(localProducts)..where((p) => p.id.equals(id)))
          .getSingleOrNull();

  Future<LocalProductRow?> findByBarcode(String barcode) =>
      (select(localProducts)..where((p) => p.sku.equals(barcode)))
          .getSingleOrNull();

  Future<void> upsertProduct(LocalProductsCompanion product) =>
      into(localProducts).insertOnConflictUpdate(product);

  Future<void> deleteProduct(String id) =>
      (delete(localProducts)..where((p) => p.id.equals(id))).go();

  Future<void> deleteAllProducts() => delete(localProducts).go();
}
