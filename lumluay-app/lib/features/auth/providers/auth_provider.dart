import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../data/auth_repository.dart';
import '../../../core/constants/app_constants.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

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

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        tenantId: json['tenantId'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        role: json['role'] as String,
      );
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

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
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
        // Rebuild AuthUser from stored data; fetch /auth/me if needed
        final userId = claims['sub'] as String?;
        final tenantId = claims['tenantId'] as String?;
        final username = claims['username'] as String?;
        final displayName = claims['displayName'] as String?;
        final role = claims['role'] as String?;
        if (userId != null && tenantId != null && username != null) {
          state = AuthAuthenticated(AuthUser(
            id: userId,
            tenantId: tenantId,
            username: username,
            displayName: displayName ?? username,
            role: role ?? 'cashier',
          ));
          return;
        }
      } catch (_) {}
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
      await _saveTokens(data, tenantSlug: tenantSlug);
      state = AuthAuthenticated(AuthUser.fromJson(data['user'] as Map<String, dynamic>));
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
      await _saveTokens(data);
      state = AuthAuthenticated(AuthUser.fromJson(data['user'] as Map<String, dynamic>));
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

  Future<void> _saveTokens(
    Map<String, dynamic> data, {
    String? tenantSlug,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.keyAccessToken, value: data['accessToken'] as String),
      _storage.write(key: AppConstants.keyRefreshToken, value: data['refreshToken'] as String),
      _storage.write(key: AppConstants.keyTenantId, value: (data['user'] as Map)['tenantId'] as String),
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
