import 'dart:convert';
import 'api_client.dart';
import '../../features/scoring/models/user_phase_score.dart';

class ScoringService {
  Future<List<UserPhaseScore>> getScores(String userId) async {
    try {
      final response = await ApiClient.instance.get(
        '/api/lineups/phase-score-history/',
      );
      final List<dynamic> history = jsonDecode(response.body);

      return history.whereType<Map>().map((stageScore) {
        final stageOrder = (stageScore['stage_order'] as num?)?.toInt();
        final stageId = (stageScore['stage'] as num?)?.toInt();
        final phaseNumber = stageOrder ?? stageId ?? 0;
        final phaseName =
            stageScore['stage_name']?.toString() ?? 'Fase $phaseNumber';
        final totalPoints =
            (stageScore['total_points'] as num?)?.toDouble() ?? 0.0;

        return UserPhaseScore(
          userId: userId,
          phaseNumber: phaseNumber,
          phaseName: phaseName,
          totalPoints: totalPoints,
          rankPosition: 0,
        );
      }).toList(growable: false);
    } catch (e) {
      throw Exception('Falha ao obter pontuações do servidor: $e');
    }
  }
}
