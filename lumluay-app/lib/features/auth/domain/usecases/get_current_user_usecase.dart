import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class GetCurrentUserUseCase {
  final FlutterSecureStorage storage;
  const GetCurrentUserUseCase(this.storage);

  Future<UserModel?> call() async {
    final userId = await storage.read(key: AppConstants.keyUserId);
    final tenantId = await storage.read(key: AppConstants.keyTenantId);
    final role = await storage.read(key: AppConstants.keyUserRole);

    if (userId == null || tenantId == null || role == null) {
      return null;
    }

    return UserModel(
      id: userId,
      tenantId: tenantId,
      username: 'cached-user',
      displayName: 'Current User',
      role: role,
    );
  }
}
