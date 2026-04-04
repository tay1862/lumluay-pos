import 'core/config/app_env.dart';
import 'main.dart';

Future<void> main() async {
  await bootstrapApp(
    const AppEnv(
      flavor: AppFlavor.prod,
      apiBaseUrl: 'https://api.lumluay.app/v1',
      wsBaseUrl: 'https://api.lumluay.app',
    ),
  );
}
