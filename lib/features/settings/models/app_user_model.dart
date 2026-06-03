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

  factory AppUserModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      final date = value?.toDate();
      if (date is DateTime) return date;
      return DateTime.now();
    }

    return AppUserModel(
      id: id,
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? (map['name'] as String).trim()
          : 'Usuario',
      email: map['email'] as String?,
      avatarUrl: (map['avatarUrl'] ?? map['photoUrl'] ?? map['photoURL'])
          as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'photoUrl': avatarUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
