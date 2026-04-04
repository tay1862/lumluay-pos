enum AppFlavor { dev, staging, prod }

class AppEnv {
  final AppFlavor flavor;
  final String apiBaseUrl;
  final String wsBaseUrl;

  const AppEnv({
    required this.flavor,
    required this.apiBaseUrl,
    required this.wsBaseUrl,
  });

  static const String _flavorValue = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'dev',
  );
  static const String _apiBaseUrlValue = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/v1',
  );
  static const String _wsBaseUrlValue = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  factory AppEnv.fromDartDefine() {
    return AppEnv(
      flavor: switch (_flavorValue) {
        'prod' => AppFlavor.prod,
        'staging' => AppFlavor.staging,
        _ => AppFlavor.dev,
      },
      apiBaseUrl: _apiBaseUrlValue,
      wsBaseUrl: _wsBaseUrlValue,
    );
  }

  bool get isProduction => flavor == AppFlavor.prod;

  String resolveApiBaseUrl(String? storedBaseUrl) {
    if (storedBaseUrl == null || storedBaseUrl.isEmpty) {
      return apiBaseUrl;
    }

    final storedUri = Uri.tryParse(storedBaseUrl);
    final envUri = Uri.tryParse(apiBaseUrl);
    if (storedUri == null || envUri == null) {
      return apiBaseUrl;
    }

    if (!isProduction) {
      return storedBaseUrl;
    }

    final isSameHost = storedUri.host == envUri.host;
    final isSecure = storedUri.scheme == 'https';
    final isCompatiblePath = storedUri.path.isEmpty ||
        storedUri.path == '/' ||
        storedUri.path.startsWith(envUri.path);

    return isSameHost && isSecure && isCompatiblePath
        ? storedBaseUrl
        : apiBaseUrl;
  }

  String get flavorName => switch (flavor) {
        AppFlavor.dev => 'dev',
        AppFlavor.staging => 'staging',
        AppFlavor.prod => 'prod',
      };
}
