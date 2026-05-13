class FantasyTeamModel {
  const FantasyTeamModel({
    required this.id,
    required this.userId,
    required this.phaseId,
    this.coachId,
    this.captainPlayerId,
    required this.totalPoints,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String phaseId;
  final String? coachId;
  final String? captainPlayerId;
  final double totalPoints;
  final DateTime createdAt;
  final DateTime updatedAt;
}
