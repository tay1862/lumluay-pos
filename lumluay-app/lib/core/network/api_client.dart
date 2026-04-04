import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../constants/app_constants.dart';
import '../config/app_env.dart';

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(currentAppEnvProvider)),
);

class ApiClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  final AppEnv _env;

  ApiClient(this._env) {
    _dio = Dio(BaseOptions(
      baseUrl: _env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final storedBaseUrl =
              await _storage.read(key: AppConstants.keyApiBaseUrl);
          final baseUrl = _env.resolveApiBaseUrl(storedBaseUrl);
          final token = await _storage.read(key: AppConstants.keyAccessToken);
          final tenantId = await _storage.read(key: AppConstants.keyTenantId);

          if (_env.isProduction &&
              storedBaseUrl != null &&
              storedBaseUrl != baseUrl) {
            await _storage.delete(key: AppConstants.keyApiBaseUrl);
          }

          options.baseUrl = baseUrl;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (tenantId != null) {
            options.headers['x-tenant-id'] = tenantId;
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              error.requestOptions.extra['retried'] != true) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry original request once; guard prevents infinite loop
              final opts = error.requestOptions;
              opts.extra['retried'] = true;
              final token =
                  await _storage.read(key: AppConstants.keyAccessToken);
              opts.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken =
          await _storage.read(key: AppConstants.keyRefreshToken);
      if (refreshToken == null) return false;

      final response = await _dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      await _storage.write(
          key: AppConstants.keyAccessToken, value: data['accessToken']);
      await _storage.write(
          key: AppConstants.keyRefreshToken, value: data['refreshToken']);
      return true;
    } catch (_) {
      return false;
    }
  }

  Dio get dio => _dio;
  String get wsBaseUrl => _env.wsBaseUrl;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    final data = response.data['data'];
    return fromJson != null ? fromJson(data) : data as T;
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.post(path, data: data);
    final rawBody = response.data;
    // 204 No Content or empty responses have no body to parse
    if (rawBody == null || (rawBody is String && rawBody.isEmpty)) {
      return fromJson != null ? fromJson(null) : null as T;
    }
    final responseData = rawBody['data'];
    return fromJson != null ? fromJson(responseData) : responseData as T;
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.put(path, data: data);
    final rawBody = response.data;
    if (rawBody == null || (rawBody is String && rawBody.isEmpty)) {
      return fromJson != null ? fromJson(null) : null as T;
    }
    final responseData = rawBody['data'];
    return fromJson != null ? fromJson(responseData) : responseData as T;
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.patch(path, data: data);
    final responseData = response.data['data'];
    return fromJson != null ? fromJson(responseData) : responseData as T;
  }

  Future<void> delete(String path) async {
    // 204 No Content is expected; any non-2xx throws DioException automatically.
    // Callers can catch DioException and inspect response.statusCode for 404/403.
    await _dio.delete<void>(path);
  }
}
