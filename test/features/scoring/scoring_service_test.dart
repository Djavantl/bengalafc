import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bengalafc/core/services/scoring_service.dart';
import 'package:bengalafc/features/scoring/models/user_phase_score.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}
class MockQuery extends Mock
    implements Query<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockQuery mockQuery;
  late MockQuerySnapshot mockSnapshot;
  late ScoringService service;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockQuery = MockQuery();
    mockSnapshot = MockQuerySnapshot();
    service = ScoringService(db: mockFirestore);
  });

  group('ScoringService', () {
    test('retorna lista de UserPhaseScore quando Firestore retorna dados', () async {
      final fakeDoc = MockQueryDocumentSnapshot();
      when(() => fakeDoc.data()).thenReturn({
        'userId': 'user123',
        'phaseNumber': 1,
        'totalPoints': 87.5,
        'rankPosition': 3,
      });

      when(() => mockFirestore.collection('user_phase_scores'))
          .thenReturn(mockCollection);
      when(() => mockCollection.where('userId', isEqualTo: 'user123'))
          .thenReturn(mockQuery);
      when(() => mockQuery.orderBy('phaseNumber', descending: true))
          .thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.docs).thenReturn([fakeDoc]);

      final result = await service.getScores('user123');

      expect(result, isA<List<UserPhaseScore>>());
      expect(result.length, 1);
      expect(result.first.totalPoints, 87.5);
    });

    test('retorna lista vazia quando não há documentos', () async {
      when(() => mockFirestore.collection('user_phase_scores'))
          .thenReturn(mockCollection);
      when(() => mockCollection.where('userId', isEqualTo: 'sem_dados'))
          .thenReturn(mockQuery);
      when(() => mockQuery.orderBy('phaseNumber', descending: true))
          .thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.docs).thenReturn([]);

      final result = await service.getScores('sem_dados');
      expect(result, isEmpty);
    });

    test('lança exceção quando Firestore falha', () async {
      when(() => mockFirestore.collection('user_phase_scores'))
          .thenReturn(mockCollection);
      when(() => mockCollection.where('userId', isEqualTo: 'user123'))
          .thenReturn(mockQuery);
      when(() => mockQuery.orderBy('phaseNumber', descending: true))
          .thenReturn(mockQuery);
      when(() => mockQuery.get()).thenThrow(Exception('Firestore offline'));

      expect(() => service.getScores('user123'), throwsException);
    });
  });
}