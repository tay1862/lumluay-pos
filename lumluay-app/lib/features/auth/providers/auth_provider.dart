import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../core/constants/app_constants.dart';
import '../data/auth_repository.dart';

class AuthUser {
  final String id;
  final String tenantId;
  final String username;
  final String displayName;
  final String role;

  const AuthUser({
    required this.id,
    required this.tenantId,
    required this.username,
    required this.displayName,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = '${json['id'] ?? json['sub'] ?? ''}'.trim();
    final tenantId = '${json['tenantId'] ?? ''}'.trim();
    final username = '${json['username'] ?? ''}'.trim();
    final displayName = '${json['displayName'] ?? username}'.trim();
    final role = '${json['role'] ?? 'cashier'}'.trim();

    if (id.isEmpty || tenantId.isEmpty || username.isEmpty) {
      throw const FormatException('Incomplete user payload');
    }

    return AuthUser(
      id: id,
      tenantId: tenantId,
      username: username,
      displayName: displayName.isEmpty ? username : displayName,
      role: role.isEmpty ? 'cashier' : role,
    );
  }
}

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AuthUser user;

  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    repository: ref.read(authRepositoryProvider),
    storage: const FlutterSecureStorage(),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final FlutterSecureStorage _storage;

  AuthNotifier({
    required AuthRepository repository,
    required FlutterSecureStorage storage,
  })  : _repository = repository,
        _storage = storage,
        super(const AuthInitial()) {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final token = await _storage.read(key: AppConstants.keyAccessToken);
    if (token != null && !JwtDecoder.isExpired(token)) {
      try {
        final claims = JwtDecoder.decode(token);
        state = AuthAuthenticated(AuthUser.fromJson(claims));
        return;
      } catch (_) {
        // Ignore broken cached sessions and reset below.
      }
    }

    await _clearTokens();
    state = const AuthUnauthenticated();
  }

  Future<void> login({
    required String tenantSlug,
    required String username,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final data = await _repository.login(
        tenantSlug: tenantSlug,
        username: username,
        password: password,
      );
      final authUser = _buildAuthUser(data);
      await _saveTokens(data, authUser: authUser, tenantSlug: tenantSlug);
      state = AuthAuthenticated(authUser);
    } catch (e) {
      state = AuthError(_parseError(e));
    }
  }

  Future<void> loginWithPin({
    required String pin,
    required String userId,
  }) async {
    state = const AuthLoading();
    try {
      final data = await _repository.loginWithPin(pin: pin, userId: userId);
      final authUser = _buildAuthUser(data);
      await _saveTokens(data, authUser: authUser);
      state = AuthAuthenticated(authUser);
    } catch (e) {
      state = AuthError(_parseError(e));
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}

    await _clearTokens();
    state = const AuthUnauthenticated();
  }

  AuthUser _buildAuthUser(Map<String, dynamic> data) {
    final rawUser = data['user'];
    if (rawUser is Map<String, dynamic>) {
      try {
        return AuthUser.fromJson(rawUser);
      } catch (_) {
        // Fall back to token claims below when the backend payload is partial.
      }
    }

    final accessToken = data['accessToken'] as String?;
    if (accessToken != null && accessToken.isNotEmpty) {
      final claims = JwtDecoder.decode(accessToken);
      return AuthUser.fromJson(claims);
    }

    throw const FormatException('Invalid login response');
  }

  Future<void> _saveTokens(
    Map<String, dynamic> data, {
    required AuthUser authUser,
    String? tenantSlug,
  }) async {
    await Future.wait([
      _storage.write(
        key: AppConstants.keyAccessToken,
        value: data['accessToken'] as String,
      ),
      _storage.write(
        key: AppConstants.keyRefreshToken,
        value: data['refreshToken'] as String,
      ),
      _storage.write(key: AppConstants.keyTenantId, value: authUser.tenantId),
      if (tenantSlug != null && tenantSlug.isNotEmpty)
        _storage.write(key: AppConstants.keyTenantSlug, value: tenantSlug),
    ]);
  }

  Future<void> _clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.keyAccessToken),
      _storage.delete(key: AppConstants.keyRefreshToken),
      _storage.delete(key: AppConstants.keyTenantId),
      _storage.delete(key: AppConstants.keyTenantSlug),
    ]);
  }

  String _parseError(Object e) {
    return e.toString().replaceAll('Exception:', '').trim();
  }
}
