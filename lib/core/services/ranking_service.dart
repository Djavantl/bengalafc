import 'dart:convert';
import 'api_client.dart';
import '../../features/ranking/models/ranking_user_score.dart';
import '../../features/settings/models/app_user_model.dart';

class RankingService {
  Future<List<RankingUserScore>> getGlobalRanking({
    required AppUserModel currentUser,
  }) async {
    try {
      final response = await ApiClient.instance.get('/api/users/profiles/');
      final List<dynamic> profilesJson = jsonDecode(response.body);

      final List<RankingUserScore> entries = [];
      for (final data in profilesJson) {
        final id = data['id']?.toString() ?? '';
        final email = data['email'] as String?;
        final firstName = data['first_name'] as String? ?? '';
        final lastName = data['last_name'] as String? ?? '';
        final name = '$firstName $lastName'.trim();
        final displayName = name.isNotEmpty ? name : (data['username'] as String? ?? 'Usuário');
        final avatar = data['photo'] as String?;
        final points = (data['points'] as num?)?.toDouble() ?? 0.0;

        String? fullAvatarUrl;
        if (avatar != null) {
          if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
            fullAvatarUrl = avatar;
          } else {
            fullAvatarUrl = '${ApiClient.instance.baseUrl}$avatar';
          }
        }

        final user = AppUserModel(
          id: id,
          name: displayName,
          email: email,
          avatarUrl: fullAvatarUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        entries.add(
          RankingUserScore(
            user: user,
            totalPoints: points,
            position: 0,
            isCurrentUser: id == currentUser.id,
          ),
        );
      }

      // Sort descending by total points
      entries.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

      // Inject ranking positions
      return [
        for (var i = 0; i < entries.length; i++)
          entries[i].copyWith(position: i + 1),
      ];
    } catch (e) {
      throw Exception('Falha ao carregar ranking do servidor: $e');
    }
  }
}
