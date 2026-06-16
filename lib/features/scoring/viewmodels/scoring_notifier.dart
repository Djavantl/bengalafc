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
