class RankingModel {
  const RankingModel({
    required this.id,
    required this.scope,
    this.leagueId,
    this.phaseId,
    required this.userId,
    required this.position,
    required this.totalPoints,
    required this.calculatedAt,
  });

  final String id;
  final String scope;
  final String? leagueId;
  final String? phaseId;
  final String userId;
  final int position;
  final double totalPoints;
  final DateTime calculatedAt;
}
