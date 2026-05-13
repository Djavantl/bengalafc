class MatchModel {
  const MatchModel({
    required this.id,
    required this.phaseId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.startsAt,
    required this.status,
    this.homeScore,
    this.awayScore,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String phaseId;
  final String homeTeamId;
  final String awayTeamId;
  final DateTime startsAt;
  final String status;
  final int? homeScore;
  final int? awayScore;
  final DateTime createdAt;
  final DateTime updatedAt;
}
