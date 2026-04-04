import '../../data/auth_repository.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class LoginUseCase {
  final AuthRepository repository;
  const LoginUseCase(this.repository);

  Future<LoginResponse> call(LoginRequest request) async {
    final json = await repository.login(
      tenantSlug: request.tenantSlug,
      username: request.username,
      password: request.password,
    );
    return LoginResponse.fromJson(json);
  }
}
