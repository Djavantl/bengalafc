class UserPhaseScore {
  final String userId;
  final int phaseNumber;
  final double totalPoints;
  final int rankPosition;

  const UserPhaseScore({
    required this.userId,
    required this.phaseNumber,
    required this.totalPoints,
    required this.rankPosition,
  });

  factory UserPhaseScore.fromMap(Map<String, dynamic> map) {
    return UserPhaseScore(
      userId: map['userId'] as String? ?? '',
      phaseNumber: (map['phaseNumber'] as num?)?.toInt() ?? 0,
      totalPoints: (map['totalPoints'] as num?)?.toDouble() ?? 0.0,
      rankPosition: (map['rankPosition'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'phaseNumber': phaseNumber,
        'totalPoints': totalPoints,
        'rankPosition': rankPosition,
      };
}