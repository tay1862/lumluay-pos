import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lumluay_pos/core/config/app_env.dart';
import 'package:lumluay_pos/core/network/api_client.dart';
import 'package:lumluay_pos/features/auth/data/auth_repository.dart';
import 'package:lumluay_pos/features/auth/presentation/pages/login_page.dart';
import 'package:lumluay_pos/features/auth/presentation/pages/pin_lock_page.dart';
import 'package:lumluay_pos/features/auth/providers/auth_provider.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository()
      : super(ApiClient(const AppEnv(
          flavor: AppFlavor.dev,
          apiBaseUrl: 'http://localhost',
          wsBaseUrl: 'http://localhost',
        )));

  @override
  Future<Map<String, dynamic>> login({
    required String tenantSlug,
    required String username,
    required String password,
  }) async {
    return {
      'accessToken': 'a',
      'refreshToken': 'r',
      'user': {
        'id': 'u1',
        'tenantId': 't1',
        'username': username,
        'displayName': 'Tester',
        'role': 'cashier',
      },
    };
  }
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier()
      : super(
          repository: FakeAuthRepository(),
          storage: const FlutterSecureStorage(),
        );
}

GoRouter _router(Widget child) => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => child),
        GoRoute(path: '/pos', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/dashboard', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/login', builder: (_, __) => const SizedBox()),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      if (call.method == 'read') return null;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  testWidgets('LoginPage shows validation errors', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1024, 768),
        builder: (_, __) => ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
          ],
          child: MaterialApp.router(routerConfig: _router(const LoginPage())),
        ),
      ),
    );

    await tester.tap(find.text('ເຂົ້າສູ່ລະບົບ'));
    await tester.pump();

    expect(find.text('ກະລຸນາປ້ອນລະຫັດຮ້ານຄ້າ'), findsOneWidget);
    expect(find.text('ກະລຸນາປ້ອນຊື່ຜູ້ໃຊ້'), findsOneWidget);
    expect(find.text('ກະລຸນາປ້ອນລະຫັດຜ່ານ'), findsOneWidget);
  });

  testWidgets('PinLockPage renders pin prompt', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1024, 768),
        builder: (_, __) => ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
          ],
          child: MaterialApp.router(routerConfig: _router(const PinLockPage(userId: 'u1'))),
        ),
      ),
    );

    expect(find.text('ກະລຸນາໃສ່ PIN'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
  });
}
