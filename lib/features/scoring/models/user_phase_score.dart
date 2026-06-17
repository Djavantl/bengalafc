class UserPhaseScore {
  final String userId;
  final int phaseNumber;
  final String phaseName;
  final double totalPoints;
  final int rankPosition;

  const UserPhaseScore({
    required this.userId,
    required this.phaseNumber,
    required this.phaseName,
    required this.totalPoints,
    required this.rankPosition,
  });

  factory UserPhaseScore.fromMap(Map<String, dynamic> map) {
    return UserPhaseScore(
      userId: map['userId'] as String? ?? '',
      phaseNumber: (map['phaseNumber'] as num?)?.toInt() ?? 0,
      phaseName: map['phaseName'] as String? ?? 'Fase',
      totalPoints: (map['totalPoints'] as num?)?.toDouble() ?? 0.0,
      rankPosition: (map['rankPosition'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'phaseNumber': phaseNumber,
        'phaseName': phaseName,
        'totalPoints': totalPoints,
        'rankPosition': rankPosition,
      };
}
