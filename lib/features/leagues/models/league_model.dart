class LeagueModel {
  const LeagueModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String ownerUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
