import '../../../../core/network/api_client.dart';
import '../models/product_models.dart';

class ProductsRemoteDataSource {
  const ProductsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<Product>> getProducts({String? categoryId, String? search}) async {
    final params = <String, String>{};
    if (categoryId != null) params['categoryId'] = categoryId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await _client.get('/products', queryParameters: params);
    // ApiClient.get() unwraps response.data['data'] which is already the list.
    final list = data as List<dynamic>;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> getProduct(String id) async {
    final data = await _client.get('/products/$id');
    return Product.fromJson(data as Map<String, dynamic>);
  }

  Future<Product> createProduct(Map<String, dynamic> body) async {
    final data = await _client.post('/products', data: body);
    return Product.fromJson(data as Map<String, dynamic>);
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> body) async {
    final data = await _client.patch('/products/$id', data: body);
    return Product.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) async {
    await _client.delete('/products/$id');
  }

  Future<ProductVariant> addVariant(
    String productId,
    Map<String, dynamic> body,
  ) async {
    final data = await _client.post('/products/$productId/variants', data: body);
    return ProductVariant.fromJson(data as Map<String, dynamic>);
  }

  Future<void> removeVariant(String productId, String variantId) async {
    await _client.delete('/products/$productId/variants/$variantId');
  }

  Future<Product> findByBarcode(String code) async {
    final data = await _client.get('/products/barcode/$code');
    return Product.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Category>> getCategories() async {
    final data = await _client.get('/categories');
    final list = data as List<dynamic>;
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Category> createCategory(String name, int sortOrder) async {
    final data = await _client.post('/categories', data: {'name': name, 'sortOrder': sortOrder});
    return Category.fromJson(data as Map<String, dynamic>);
  }

  Future<Category> updateCategory(String id, String name, int sortOrder) async {
    final data = await _client.patch('/categories/$id', data: {'name': name, 'sortOrder': sortOrder});
    return Category.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String id) async {
    await _client.delete('/categories/$id');
  }

  Future<void> reorderCategories(List<Map<String, dynamic>> items) async {
    await _client.patch('/categories/reorder', data: {'items': items});
  }
}
