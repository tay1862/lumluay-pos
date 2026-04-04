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

  String get flavorName => switch (flavor) {
        AppFlavor.dev => 'dev',
        AppFlavor.staging => 'staging',
        AppFlavor.prod => 'prod',
      };
}
