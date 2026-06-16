import 'dart:convert';
import 'api_client.dart';
import '../../features/ranking/models/ranking_user_score.dart';
import '../../features/settings/models/app_user_model.dart';

class RankingService {
  Future<List<RankingUserScore>> getGlobalRanking({
    required AppUserModel currentUser,
  }) async {
    try {
      final response = await ApiClient.instance.get('/api/ranking/global/');
      final List<dynamic> rankingJson = jsonDecode(response.body);

      return [
        for (final data in rankingJson)
          _parseRankingEntry(data, currentUser),
      ];
    } catch (e) {
      throw Exception('Falha ao carregar ranking do servidor: $e');
    }
  }

  RankingUserScore _parseRankingEntry(
    dynamic data,
    AppUserModel currentUser,
  ) {
    if (data is Map) {
      final id = data['id']?.toString() ?? '';
      final username = data['username']?.toString() ?? 'Usuário';
      final points = (data['points'] as num?)?.toDouble() ?? 0.0;
      final position = (data['position'] as num?)?.toInt() ?? 0;

      return RankingUserScore(
        user: AppUserModel(
          id: id,
          name: username,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        totalPoints: points,
        position: position,
        isCurrentUser: id == currentUser.id,
      );
    }

    return RankingUserScore(
      user: AppUserModel(
        id: '',
        name: 'Usuário',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      totalPoints: 0,
      position: 0,
      isCurrentUser: false,
    );
  }
}
