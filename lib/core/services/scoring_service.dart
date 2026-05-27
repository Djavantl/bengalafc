import '../../features/scoring/models/user_phase_score.dart';

class ScoringService {
  Future<List<UserPhaseScore>> getScores(String userId) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      UserPhaseScore(
        userId: userId,
        phaseNumber: 1,
        totalPoints: 92.5,
        rankPosition: 2,
      ),
      UserPhaseScore(
        userId: userId,
        phaseNumber: 2,
        totalPoints: 78.0,
        rankPosition: 4,
      ),
      UserPhaseScore(
        userId: userId,
        phaseNumber: 3,
        totalPoints: 85.5,
        rankPosition: 3,
      ),
    ];
  }
}