class CoachMatchStatsModel {
  const CoachMatchStatsModel({
    required this.id,
    required this.coachId,
    required this.matchId,
    required this.points,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String coachId;
  final String matchId;
  final double points;
  final DateTime createdAt;
  final DateTime updatedAt;
}
