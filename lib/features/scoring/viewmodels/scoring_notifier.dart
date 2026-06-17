import 'package:flutter/foundation.dart';
import '../../../core/services/scoring_service.dart';
import '../models/user_phase_score.dart';

enum ScoringStatus { idle, loading, success, error }

class ScoringNotifier extends ChangeNotifier {
  final ScoringService _service;

  ScoringNotifier(this._service);

  List<UserPhaseScore> scores = [];
  ScoringStatus status = ScoringStatus.idle;
  String? errorMessage;

  // ✅ getter exigido pelo teste
  double get totalPoints =>
      scores.fold(0.0, (sum, s) => sum + s.totalPoints);

  // ✅ getter exigido pelo teste — retorna null se não houver scores
  int? get bestRank {
    if (scores.isEmpty) return null;
    return scores
        .map((s) => s.rankPosition)
        .where((r) => r > 0)
        .fold<int?>(null, (best, r) => best == null || r < best ? r : best);
  }

  Future<void> load(String userId) async {
    status = ScoringStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      scores = await _service.getScores(userId);
      status = ScoringStatus.success;
    } catch (e) {
      status = ScoringStatus.error;
      errorMessage = 'Não foi possível carregar as pontuações.';
    }

    notifyListeners();
  }
}