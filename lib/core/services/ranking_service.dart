import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../features/ranking/models/ranking_user_score.dart';
import '../../features/settings/models/app_user_model.dart';

class RankingService {
  Future<List<RankingUserScore>> getGlobalRanking({
    required AppUserModel currentUser,
  }) async {
    final users = await _loadUsers(currentUser);
    final entries = users
        .map(
          (user) => RankingUserScore(
            user: user,
            totalPoints: _mockPointsForUser(user.id),
            position: 0,
            isCurrentUser: user.id == currentUser.id,
          ),
        )
        .toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    return [
      for (var i = 0; i < entries.length; i++)
        entries[i].copyWith(position: i + 1),
    ];
  }

  Future<List<AppUserModel>> _loadUsers(AppUserModel currentUser) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .orderBy('name')
            .get();

        final users = snapshot.docs
            .map((doc) => AppUserModel.fromMap(doc.id, doc.data()))
            .toList();

        if (users.isNotEmpty) {
          return _withCurrentUser(users, currentUser);
        }
      } catch (_) {
        // Keeps the ranking useful during local development or missing rules.
      }
    }

    return _withCurrentUser(_mockUsers(currentUser), currentUser);
  }

  List<AppUserModel> _withCurrentUser(
    List<AppUserModel> users,
    AppUserModel currentUser,
  ) {
    final filtered = users.where((user) => user.id != currentUser.id).toList();
    return [currentUser, ...filtered];
  }

  List<AppUserModel> _mockUsers(AppUserModel currentUser) {
    final now = DateTime.now();
    return [
      currentUser,
      AppUserModel(
        id: 'mock_lia',
        name: 'Lia Campos',
        email: 'lia@bengalafc.com',
        avatarUrl: 'https://i.pravatar.cc/160?img=47',
        createdAt: now,
        updatedAt: now,
      ),
      AppUserModel(
        id: 'mock_rafa',
        name: 'Rafa Nogueira',
        email: 'rafa@bengalafc.com',
        avatarUrl: 'https://i.pravatar.cc/160?img=12',
        createdAt: now,
        updatedAt: now,
      ),
      AppUserModel(
        id: 'mock_malu',
        name: 'Malu Ribeiro',
        email: 'malu@bengalafc.com',
        avatarUrl: 'https://i.pravatar.cc/160?img=32',
        createdAt: now,
        updatedAt: now,
      ),
      AppUserModel(
        id: 'mock_bruno',
        name: 'Bruno Costa',
        email: 'bruno@bengalafc.com',
        avatarUrl: 'https://i.pravatar.cc/160?img=68',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  double _mockPointsForUser(String userId) {
    final hash = userId.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return 64 + (hash % 520) / 10;
  }
}
