import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';

class CheckAuthUseCase {
  final FlutterSecureStorage storage;
  const CheckAuthUseCase(this.storage);

  Future<bool> call() async {
    final token = await storage.read(key: AppConstants.keyAccessToken);
    return token != null && token.isNotEmpty;
  }
}
