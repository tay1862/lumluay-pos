import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class Customer {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final int points;
  final bool isActive;
  final DateTime? createdAt;

  const Customer({
    required this.id,
    this.name,
    this.phone,
    this.email,
    this.points = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as String,
        name: j['name'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        points: (j['points'] as num?)?.toInt() ?? 0,
        isActive: j['isActive'] as bool? ?? true,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

class CustomersRepository {
  const CustomersRepository(this._client);

  final ApiClient _client;

  Future<List<Customer>> getCustomers({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await _client.get<List<dynamic>>('/members', queryParameters: params);
    return data.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Customer> getCustomer(String id) async {
    final data = await _client.get<Map<String, dynamic>>('/members/$id');
    return Customer.fromJson(data);
  }

  Future<Customer> createCustomer(Map<String, dynamic> body) async {
    final data = await _client.post<Map<String, dynamic>>('/members', data: body);
    return Customer.fromJson(data);
  }

  Future<Customer> updateCustomer(String id, Map<String, dynamic> body) async {
    final data = await _client.patch<Map<String, dynamic>>('/members/$id', data: body);
    return Customer.fromJson(data);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(ref.read(apiClientProvider));
});

final customersListProvider = FutureProvider.family<List<Customer>, String?>(
  (ref, search) {
    return ref.read(customersRepositoryProvider).getCustomers(search: search);
  },
);
