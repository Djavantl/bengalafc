class FantasyTeamPlayerModel {
  const FantasyTeamPlayerModel({
    required this.id,
    required this.fantasyTeamId,
    required this.playerId,
    required this.slotIndex,
    required this.isCaptain,
    required this.points,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fantasyTeamId;
  final String playerId;
  final int slotIndex;
  final bool isCaptain;
  final double points;
  final DateTime createdAt;
  final DateTime updatedAt;
}
