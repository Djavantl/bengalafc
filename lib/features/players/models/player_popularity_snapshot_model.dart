class PlayerPopularitySnapshotModel {
  const PlayerPopularitySnapshotModel({
    required this.id,
    required this.playerId,
    this.phaseId,
    required this.selectedCount,
    required this.selectedPercentage,
    required this.capturedAt,
  });

  final String id;
  final String playerId;
  final String? phaseId;
  final int selectedCount;
  final double selectedPercentage;
  final DateTime capturedAt;
}
