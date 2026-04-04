class AppConstants {
  // API
  static const String defaultApiBaseUrl = 'http://localhost:3000/v1';

  // Storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyTenantId = 'tenant_id';
  static const String keyTenantSlug = 'tenant_slug';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyApiBaseUrl = 'api_base_url';

  // App
  static const String appName = 'LUMLUAY POS';
  static const int maxPinLength = 6;
  static const Duration sessionTimeout = Duration(minutes: 15);
  static const Duration syncInterval = Duration(seconds: 30);
}
