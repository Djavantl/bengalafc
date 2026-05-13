class TournamentPhaseModel {
  const TournamentPhaseModel({
    required this.id,
    required this.name,
    required this.phaseType,
    this.startsAt,
    this.endsAt,
    this.transferDeadlineAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phaseType;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? transferDeadlineAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
