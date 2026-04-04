import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/database/app_database.dart';
import 'models/product_models.dart';
import 'datasources/products_remote_datasource.dart';
import 'datasources/products_local_datasource.dart';

export 'models/product_models.dart';

class ProductsRepository {
  ProductsRepository(this._remote, this._local, this._connectivity);

  final ProductsRemoteDataSource _remote;
  final ProductsLocalDataSource _local;
  final ConnectivityService _connectivity;

  Future<List<Product>> getProducts({String? categoryId, String? search}) async {
    final online = await _connectivity.isOnline;
    if (online) {
      try {
        final products =
            await _remote.getProducts(categoryId: categoryId, search: search);
        await _local.cacheProducts(products);
        return products;
      } catch (_) {}
    }
    return _local.getProducts(categoryId: categoryId, search: search);
  }

  Future<Product> getProduct(String id) async {
    final online = await _connectivity.isOnline;
    if (online) {
      try {
        final product = await _remote.getProduct(id);
        await _local.upsertProduct(product);
        return product;
      } catch (_) {}
    }
    final local = await _local.getProduct(id);
    if (local != null) return local;
    return _remote.getProduct(id);
  }

  Future<Product> createProduct(Map<String, dynamic> body) async {
    final product = await _remote.createProduct(body);
    await _local.upsertProduct(product);
    return product;
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> body) async {
    final product = await _remote.updateProduct(id, body);
    await _local.upsertProduct(product);
    return product;
  }

  Future<void> deleteProduct(String id) async {
    await _remote.deleteProduct(id);
    await _local.removeProduct(id);
  }

  Future<ProductVariant> addVariant(
    String productId,
    Map<String, dynamic> body,
  ) async {
    final variant = await _remote.addVariant(productId, body);
    final product = await getProduct(productId);
    final updated = Product(
      id: product.id,
      name: product.name,
      basePrice: product.basePrice,
      sku: product.sku,
      imageUrl: product.imageUrl,
      productType: product.productType,
      isActive: product.isActive,
      category: product.category,
      stock: product.stock,
      variants: [...product.variants, variant],
      modifierGroups: product.modifierGroups,
    );
    await _local.upsertProduct(updated);
    return variant;
  }

  Future<void> removeVariant(String productId, String variantId) async {
    await _remote.removeVariant(productId, variantId);
    final product = await getProduct(productId);
    final updated = Product(
      id: product.id,
      name: product.name,
      basePrice: product.basePrice,
      sku: product.sku,
      imageUrl: product.imageUrl,
      productType: product.productType,
      isActive: product.isActive,
      category: product.category,
      stock: product.stock,
      variants: product.variants.where((v) => v.id != variantId).toList(),
      modifierGroups: product.modifierGroups,
    );
    await _local.upsertProduct(updated);
  }

  Future<Product> findByBarcode(String code) async {
    final online = await _connectivity.isOnline;
    if (online) {
      try {
        final product = await _remote.findByBarcode(code);
        await _local.upsertProduct(product);
        return product;
      } catch (_) {}
    }
    final local = await _local.findByBarcode(code);
    if (local != null) return local;
    return _remote.findByBarcode(code);
  }

  Future<List<Category>> getCategories() async {
    final online = await _connectivity.isOnline;
    if (online) {
      try {
        final categories = await _remote.getCategories();
        await _local.cacheCategories(categories);
        return categories;
      } catch (_) {}
    }
    return _local.getCategories();
  }

  Future<Category> createCategory(String name, int sortOrder) async {
    final category = await _remote.createCategory(name, sortOrder);
    await _local.upsertCategory(category);
    return category;
  }

  Future<Category> updateCategory(String id, String name, int sortOrder) async {
    final category = await _remote.updateCategory(id, name, sortOrder);
    await _local.upsertCategory(category);
    return category;
  }

  Future<void> deleteCategory(String id) async {
    await _remote.deleteCategory(id);
    await _local.removeCategory(id);
  }

  Future<void> reorderCategories(List<Map<String, dynamic>> items) async {
    await _remote.reorderCategories(items);
    await _local.reorderCategories(items);
  }
}

final productsRemoteDataSourceProvider = Provider((ref) {
  return ProductsRemoteDataSource(ref.watch(apiClientProvider));
});

final productsLocalDataSourceProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProductsLocalDataSource(db.productsDao);
});

final productsRepositoryProvider = Provider((ref) {
  return ProductsRepository(
    ref.watch(productsRemoteDataSourceProvider),
    ref.watch(productsLocalDataSourceProvider),
    ref.watch(connectivityServiceProvider),
  );
});

final productsCategoryFilterProvider = StateProvider<String?>((ref) => null);
final productsSearchProvider = StateProvider<String>((ref) => '');

final productsListProvider = FutureProvider((ref) {
  final repo = ref.watch(productsRepositoryProvider);
  final category = ref.watch(productsCategoryFilterProvider);
  final search = ref.watch(productsSearchProvider);
  return repo.getProducts(categoryId: category, search: search);
});

final categoriesListProvider = FutureProvider((ref) {
  return ref.watch(productsRepositoryProvider).getCategories();
});
