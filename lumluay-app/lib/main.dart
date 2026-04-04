import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/localization/locale_notifier.dart';
import 'core/config/app_env.dart';
import 'core/services/fcm_service.dart';

final currentAppEnvProvider = Provider<AppEnv>(
  (ref) => throw UnimplementedError('AppEnv override is required'),
);

void main() async {
  await bootstrapApp(AppEnv.fromDartDefine());
}

Future<void> bootstrapApp(AppEnv env) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        currentAppEnvProvider.overrideWithValue(env),
      ],
      child: LumluayApp(env: env),
    ),
  );
  unawaited(_initializeOptionalFirebase());
}

Future<void> _initializeOptionalFirebase() async {
  try {
    await Firebase.initializeApp();
    await FcmService.instance.init();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'bootstrapApp',
        context: ErrorDescription(
          'while initializing optional Firebase services',
        ),
      ),
    );
  }
}

class LumluayApp extends ConsumerWidget {
  const LumluayApp({super.key, required this.env});

  final AppEnv env;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);
    return ScreenUtilInit(
      designSize: const Size(1024, 768),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp.router(
        onGenerateTitle: (context) => '${AppLocalizations.of(context).appTitle} (${env.flavorName.toUpperCase()})',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }
}
