import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider)),
);

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  Future<Map<String, dynamic>> login({
    required String tenantSlug,
    required String username,
    required String password,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'username': username,
        'password': password,
        'tenantSlug': tenantSlug,
      },
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    return data;
  }

  Future<Map<String, dynamic>> loginWithPin({
    required String pin,
    required String userId,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/login/pin',
      data: {'userId': userId, 'pin': pin},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
    return data;
  }

  Future<void> logout() async {
    await _api.post<void>('/auth/logout');
  }
}
