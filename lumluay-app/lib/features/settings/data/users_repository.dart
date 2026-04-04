import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────
class AppUser {
  final String id;
  final String username;
  final String displayName;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) {
    return AppUser(
      id: '${j['id']}',
      username: '${j['username']}',
      displayName: '${j['displayName']}',
      role: '${j['role']}',
      isActive: j['isActive'] == true || j['isActive'] == 1,
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse('${j['createdAt']}')
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────
class UsersRepository {
  const UsersRepository(this._client);
  final ApiClient _client;

  Future<List<AppUser>> getUsers() async {
    final data = await _client.get('/users');
    final list = (data['items'] ?? data) as List<dynamic>;
    return list
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppUser> createUser(Map<String, dynamic> body) async {
    final data = await _client.post('/users', data: body);
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<AppUser> updateUser(String id, Map<String, dynamic> body) async {
    final data = await _client.patch('/users/$id', data: body);
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteUser(String id) async {
    await _client.delete('/users/$id');
  }

  Future<void> changePassword(
      String id, String currentPassword, String newPassword) async {
    await _client.patch('/users/$id/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> setPin(String id, String pin) async {
    await _client.patch('/users/$id/pin', data: {'pin': pin});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final usersRepositoryProvider = Provider((ref) {
  return UsersRepository(ref.watch(apiClientProvider));
});

final usersListProvider = FutureProvider((ref) {
  return ref.watch(usersRepositoryProvider).getUsers();
});
