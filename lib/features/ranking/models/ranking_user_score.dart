import '../../settings/models/app_user_model.dart';

class RankingUserScore {
  const RankingUserScore({
    required this.user,
    required this.position,
    required this.totalPoints,
    required this.isCurrentUser,
  });

  final AppUserModel user;
  final int position;
  final double totalPoints;
  final bool isCurrentUser;

  RankingUserScore copyWith({
    AppUserModel? user,
    int? position,
    double? totalPoints,
    bool? isCurrentUser,
  }) {
    return RankingUserScore(
      user: user ?? this.user,
      position: position ?? this.position,
      totalPoints: totalPoints ?? this.totalPoints,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}
