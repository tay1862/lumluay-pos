import '../../data/auth_repository.dart';
import '../models/login_response.dart';

class PinLoginUseCase {
  final AuthRepository repository;
  const PinLoginUseCase(this.repository);

  Future<LoginResponse> call({
    required String pin,
    required String userId,
  }) async {
    final json = await repository.loginWithPin(pin: pin, userId: userId);
    return LoginResponse.fromJson(json);
  }
}
