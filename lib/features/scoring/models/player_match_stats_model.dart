class PlayerMatchStatsModel {
  const PlayerMatchStatsModel({
    required this.id,
    required this.playerId,
    required this.matchId,
    required this.goals,
    required this.assists,
    required this.cleanSheet,
    required this.difficultSaves,
    required this.yellowCards,
    required this.redCards,
    required this.points,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String playerId;
  final String matchId;
  final int goals;
  final int assists;
  final bool cleanSheet;
  final int difficultSaves;
  final int yellowCards;
  final int redCards;
  final double points;
  final DateTime createdAt;
  final DateTime updatedAt;
}
