class CoachModel {
  const CoachModel({
    required this.id,
    required this.nationalTeamId,
    required this.name,
    this.photoUrl,
    required this.totalPoints,
    required this.selectedPercentage,
    required this.selectedCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nationalTeamId;
  final String name;
  final String? photoUrl;
  final double totalPoints;
  final double selectedPercentage;
  final int selectedCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
