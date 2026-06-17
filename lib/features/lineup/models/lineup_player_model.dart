class LineupPlayerModel {
  const LineupPlayerModel({
    required this.id,
    required this.name,
    required this.nationalTeam,
    required this.position,
    required this.averagePoints,
    required this.selectedPercentage,
    required this.isStarter,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String nationalTeam;
  final String position;
  final double averagePoints;
  final double selectedPercentage;
  final bool isStarter;
  final String? photoUrl;

  LineupPlayerModel copyWith({
    String? id,
    String? name,
    String? nationalTeam,
    String? position,
    double? averagePoints,
    double? selectedPercentage,
    bool? isStarter,
    String? photoUrl,
  }) {
    return LineupPlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nationalTeam: nationalTeam ?? this.nationalTeam,
      position: position ?? this.position,
      averagePoints: averagePoints ?? this.averagePoints,
      selectedPercentage: selectedPercentage ?? this.selectedPercentage,
      isStarter: isStarter ?? this.isStarter,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
