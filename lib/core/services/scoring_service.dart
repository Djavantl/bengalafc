import 'dart:convert';
import 'api_client.dart';
import '../../features/scoring/models/user_phase_score.dart';

class ScoringService {
  Future<List<UserPhaseScore>> getScores(String userId) async {
    try {
      final stagesResponse = await ApiClient.instance.get('/api/stages/');
      final List<dynamic> stagesJson = jsonDecode(stagesResponse.body);
      final stageNamesById = <int, String>{
        for (final stage in stagesJson)
          if (stage is Map && stage['id'] is int)
            stage['id'] as int: stage['name']?.toString() ?? 'Fase',
      };
      final stageOrdersById = <int, int>{
        for (final stage in stagesJson)
          if (stage is Map && stage['id'] is int)
            stage['id'] as int:
                (stage['order'] as num?)?.toInt() ?? (stage['id'] as int),
      };

      final response = await ApiClient.instance.get('/api/lineups/');
      final List<dynamic> lineups = jsonDecode(response.body);

      final List<UserPhaseScore> scores = [];
      for (final lineup in lineups) {
        final lineupId = lineup['id'];
        final stageId = lineup['stage'];
        final stageIdValue = stageId is int ? stageId : 1;
        final stageNumber = stageOrdersById[stageIdValue] ?? stageIdValue;
        final stageName = stageNamesById[stageIdValue] ?? 'Fase $stageNumber';

        try {
          final historyResponse = await ApiClient.instance.get('/api/lineups/$lineupId/score-history/');
          final historyData = jsonDecode(historyResponse.body);
          final double totalPoints = (historyData['total_points'] as num?)?.toDouble() ?? 0.0;

          scores.add(
            UserPhaseScore(
              userId: userId,
              phaseNumber: stageNumber,
              phaseName: stageName,
              totalPoints: totalPoints,
              rankPosition: 0,
            ),
          );
        } catch (_) {
          scores.add(
            UserPhaseScore(
              userId: userId,
              phaseNumber: stageNumber,
              phaseName: stageName,
              totalPoints: 0.0,
              rankPosition: 0,
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
