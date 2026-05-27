import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/scoring/models/user_phase_score.dart';

class ScoringService {
  final FirebaseFirestore _db;

  ScoringService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<List<UserPhaseScore>> getScores(String userId) async {
    final snap = await _db
        .collection('user_phase_scores')
        .where('userId', isEqualTo: userId)
        .orderBy('phaseNumber', descending: true)
        .get();

    return snap.docs.map((d) => UserPhaseScore.fromMap(d.data())).toList();
  }
}