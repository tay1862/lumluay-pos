class LoginRequest {
  final String tenantSlug;
  final String username;
  final String password;

  const LoginRequest({
    required this.tenantSlug,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'tenantSlug': tenantSlug,
        'username': username,
        'password': password,
      };
}
