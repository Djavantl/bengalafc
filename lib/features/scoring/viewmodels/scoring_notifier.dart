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

  double get totalPoints =>
      scores.fold(0.0, (sum, s) => sum + s.totalPoints);

  int get bestRank => scores.isEmpty
      ? 0
      : scores.map((s) => s.rankPosition).reduce((a, b) => a < b ? a : b);

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