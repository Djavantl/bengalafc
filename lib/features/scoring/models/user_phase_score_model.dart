class UserPhaseScoreModel {
  const UserPhaseScoreModel({
    required this.id,
    required this.userId,
    required this.phaseId,
    required this.fantasyTeamId,
    required this.basePoints,
    required this.captainBonusPoints,
    required this.totalPoints,
    this.calculatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String phaseId;
  final String fantasyTeamId;
  final double basePoints;
  final double captainBonusPoints;
  final double totalPoints;
  final DateTime? calculatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
