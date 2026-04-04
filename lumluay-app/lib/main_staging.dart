import 'core/config/app_env.dart';
import 'main.dart';

Future<void> main() async {
  await bootstrapApp(
    const AppEnv(
      flavor: AppFlavor.staging,
      apiBaseUrl: 'https://staging-api.lumluay.app/v1',
      wsBaseUrl: 'https://staging-api.lumluay.app',
    ),
  );
}
