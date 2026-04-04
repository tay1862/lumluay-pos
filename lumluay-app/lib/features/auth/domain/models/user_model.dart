class UserModel {
  final String id;
  final String tenantId;
  final String username;
  final String displayName;
  final String role;

  const UserModel({
    required this.id,
    required this.tenantId,
    required this.username,
    required this.displayName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        tenantId: json['tenantId'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        role: json['role'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'username': username,
        'displayName': displayName,
        'role': role,
      };
}
