class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
}
