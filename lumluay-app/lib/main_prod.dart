import 'core/config/app_env.dart';
import 'main.dart';

Future<void> main() async {
  await bootstrapApp(
    const AppEnv(
      flavor: AppFlavor.prod,
      apiBaseUrl: 'https://kanghan.site/api',
      wsBaseUrl: 'https://kanghan.site',
    ),
  );
}
