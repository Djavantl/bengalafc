import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bengalafc/core/services/scoring_service.dart';
import 'package:bengalafc/features/scoring/models/user_phase_score.dart';
import 'package:bengalafc/features/scoring/viewmodels/scoring_notifier.dart';

class MockScoringService extends Mock implements ScoringService {}

void main() {
  late MockScoringService mockService;
  late ScoringNotifier notifier;

  setUp(() {
    mockService = MockScoringService();
    notifier = ScoringNotifier(mockService);
  });

  final fakeScores = [
    const UserPhaseScore(        // ✅ const
      userId: 'user_1',
      phaseNumber: 1,
      phaseName: 'Fase 1',       // ✅ adicionado
      totalPoints: 85.0,
      rankPosition: 3,
    ),
    const UserPhaseScore(        // ✅ const
      userId: 'user_1',
      phaseNumber: 2,
      phaseName: 'Fase 2',       // ✅ adicionado
      totalPoints: 60.0,
      rankPosition: 5,
    ),
  ];

  group('ScoringNotifier', () {
    test('estado inicial é idle', () {
      expect(notifier.status, ScoringStatus.idle);
      expect(notifier.scores, isEmpty);
      expect(notifier.errorMessage, isNull);
    });

    test('load com sucesso atualiza status para success e popula scores', () async {
      when(() => mockService.getScores('user_1'))
          .thenAnswer((_) async => fakeScores);

      await notifier.load('user_1');

      expect(notifier.status, ScoringStatus.success);
      expect(notifier.scores.length, 2);
      expect(notifier.scores.first.phaseNumber, 1);
    });

    test('totalPoints soma corretamente', () async {
      when(() => mockService.getScores('user_1'))
          .thenAnswer((_) async => fakeScores);

      await notifier.load('user_1');

      expect(notifier.totalPoints, 145.0);
    });

    test('bestRank retorna o menor rankPosition', () async {
      when(() => mockService.getScores('user_1'))
          .thenAnswer((_) async => fakeScores);

      await notifier.load('user_1');

      expect(notifier.bestRank, 3);
    });

    test('load com lista vazia mantém status success e scores vazio', () async {
      when(() => mockService.getScores('user_1'))
          .thenAnswer((_) async => []);

      await notifier.load('user_1');

      expect(notifier.status, ScoringStatus.success);
      expect(notifier.scores, isEmpty);
    });

    test('load com erro atualiza status para error', () async {
      when(() => mockService.getScores('user_1'))
          .thenThrow(Exception('Firestore offline'));

      await notifier.load('user_1');

      expect(notifier.status, ScoringStatus.error);
      expect(notifier.errorMessage, isNotNull);
    });
  });
}