class ScoringRuleModel {
  const ScoringRuleModel({
    required this.id,
    required this.eventCode,
    required this.description,
    required this.points,
    required this.appliesTo,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String eventCode;
  final String description;
  final double points;
  final String appliesTo;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
