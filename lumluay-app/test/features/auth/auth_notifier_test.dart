import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/core/config/app_env.dart';
import 'package:lumluay_pos/core/network/api_client.dart';
import 'package:lumluay_pos/features/auth/data/auth_repository.dart';
import 'package:lumluay_pos/features/auth/providers/auth_provider.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(ApiClient(const AppEnv(flavor: AppFlavor.dev, apiBaseUrl: 'http://localhost', wsBaseUrl: 'http://localhost')));

  @override
  Future<Map<String, dynamic>> login({
    required String tenantSlug,
    required String username,
    required String password,
  }) async {
    return {
      'accessToken': 'token-a',
      'refreshToken': 'token-r',
      'user': {
        'id': 'u1',
        'tenantId': 't1',
        'username': username,
        'displayName': 'Tester',
        'role': 'cashier',
      },
    };
  }

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final store = <String, String>{};
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    store.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          return store[call.arguments['key'] as String];
        case 'write':
          store[call.arguments['key'] as String] = call.arguments['value'] as String;
          return null;
        case 'delete':
          store.remove(call.arguments['key'] as String);
          return null;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('login transitions to AuthAuthenticated', () async {
    final notifier = AuthNotifier(
      repository: FakeAuthRepository(),
      storage: const FlutterSecureStorage(),
    );

    await notifier.login(tenantSlug: 'demo', username: 'cashier', password: '1234');

    expect(notifier.state, isA<AuthAuthenticated>());
  });
}
