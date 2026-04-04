import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/core/services/connectivity_service.dart';
import 'package:lumluay_pos/features/products/data/datasources/products_local_datasource.dart';
import 'package:lumluay_pos/features/products/data/datasources/products_remote_datasource.dart';
import 'package:lumluay_pos/features/products/data/products_repository.dart';
import 'package:mocktail/mocktail.dart';

class FakeConnectivityService extends ConnectivityService {
  FakeConnectivityService(this.online);
  final bool online;
  @override
  Future<bool> get isOnline async => online;
}

class MockRemote extends Mock implements ProductsRemoteDataSource {}

class MockLocal extends Mock implements ProductsLocalDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(<Product>[]);
  });

  test('ProductsRepository uses remote when online', () async {
    final remote = MockRemote();
    final local = MockLocal();

    final remoteProducts = [
      const Product(
        id: 'p1',
        name: 'Coffee',
        basePrice: 60,
        productType: 'simple',
        isActive: true,
      ),
    ];

    when(() => remote.getProducts(categoryId: any(named: 'categoryId'), search: any(named: 'search')))
        .thenAnswer((_) async => remoteProducts);
    when(() => local.cacheProducts(any())).thenAnswer((_) async {});

    final repo = ProductsRepository(remote, local, FakeConnectivityService(true));

    final products = await repo.getProducts();
    expect(products.first.id, 'p1');
    verify(() => local.cacheProducts(remoteProducts)).called(1);
  });

  test('ProductsRepository falls back to local when offline', () async {
    final remote = MockRemote();
    final local = MockLocal();

    final localProducts = [
      const Product(
        id: 'p2',
        name: 'Tea',
        basePrice: 40,
        productType: 'simple',
        isActive: true,
      ),
    ];

    when(() => local.getProducts(categoryId: any(named: 'categoryId'), search: any(named: 'search')))
        .thenAnswer((_) async => localProducts);

    final repo = ProductsRepository(remote, local, FakeConnectivityService(false));

    final products = await repo.getProducts();
    expect(products.first.id, 'p2');
    verifyNever(() => remote.getProducts(categoryId: any(named: 'categoryId'), search: any(named: 'search')));
  });
}
