import 'dart:convert';
import 'api_client.dart';
import '../../features/scoring/models/user_phase_score.dart';

class ScoringService {
  Future<List<UserPhaseScore>> getScores(String userId) async {
    try {
      final response = await ApiClient.instance.get('/api/lineups/');
      final List<dynamic> lineups = jsonDecode(response.body);

      final List<UserPhaseScore> scores = [];
      for (final lineup in lineups) {
        final lineupId = lineup['id'];
        final stageId = lineup['stage'];

        try {
          final historyResponse = await ApiClient.instance.get('/api/lineups/$lineupId/score-history/');
          final historyData = jsonDecode(historyResponse.body);
          final double totalPoints = (historyData['total_points'] as num?)?.toDouble() ?? 0.0;

          scores.add(
            UserPhaseScore(
              userId: userId,
              phaseNumber: stageId is int ? stageId : 1,
              totalPoints: totalPoints,
              rankPosition: 1, // Default rank position since backend does not calculate phase-specific ranks
            ),
          );
        } catch (_) {
          scores.add(
            UserPhaseScore(
              userId: userId,
              phaseNumber: stageId is int ? stageId : 1,
              totalPoints: 0.0,
              rankPosition: 1,
            ),
          );
        }
      }

      return scores;
    } catch (e) {
      throw Exception('Falha ao obter pontuações do servidor: $e');
    }
  }
}