class NationalTeamModel {
  const NationalTeamModel({
    required this.id,
    required this.name,
    required this.code,
    this.flagUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final String? flagUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
}
