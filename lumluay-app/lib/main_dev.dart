import 'core/config/app_env.dart';
import 'main.dart';

Future<void> main() async {
  await bootstrapApp(
    const AppEnv(
      flavor: AppFlavor.dev,
      apiBaseUrl: 'http://localhost:3000/v1',
      wsBaseUrl: 'http://localhost:3000',
    ),
  );
}
