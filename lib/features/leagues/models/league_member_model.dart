class LeagueMemberModel {
  const LeagueMemberModel({
    required this.id,
    required this.leagueId,
    required this.userId,
    required this.joinedAt,
  });

  final String id;
  final String leagueId;
  final String userId;
  final DateTime joinedAt;
}
