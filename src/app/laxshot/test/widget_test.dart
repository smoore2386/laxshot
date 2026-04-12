import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:laxshot/data/services/ml_analysis_service.dart';
import 'package:laxshot/data/services/shot_coaching_service.dart';
import 'package:laxshot/data/models/user_model.dart';
import 'package:laxshot/data/models/stats_model.dart';
import 'package:laxshot/data/models/session_model.dart';
import 'package:laxshot/data/models/shot_classification.dart';
import 'package:laxshot/features/stats/widgets/stat_summary_card.dart';
import 'package:laxshot/presentation/widgets/laxshot_logo.dart';

// ── Helpers ───────────────────────────────────────────────────────────────

UserModel _makeUser({required DateTime dob, bool isMinor = false}) => UserModel(
      uid: 'uid-test',
      email: 'test@example.com',
      displayName: 'Test Athlete',
      dateOfBirth: dob,
      position: PlayerPosition.attacker,
      isMinor: isMinor,
      parentApproved: true,
      createdAt: DateTime(2024),
    );

StatsModel _makeStats({int totalShots = 0, int totalSuccessful = 0, double bestAccuracy = 0.0}) =>
    StatsModel(
      userId: 'uid-test',
      totalSessions: 1,
      totalShots: totalShots,
      totalSuccessful: totalSuccessful,
      lifetimeZoneAccuracy: ZoneAccuracy.empty(),
      bestAccuracy: bestAccuracy,
      currentStreak: 0,
      longestStreak: 0,
      unlockedAchievements: [],
      lastUpdated: DateTime(2025),
    );

void main() {
  // ── MlAnalysisService ─────────────────────────────────────────────────────
  group('MlAnalysisService', () {
    late MlAnalysisService service;

    setUp(() => service = MlAnalysisService());
    tearDown(() => service.dispose());

    test('initialize completes without error', () async {
      await expectLater(service.initialize(), completes);
    });

    test('analyzeFrame returns a ShotAnalysisResult with valid score', () async {
      final result = await service.analyzeFrame('/fake/path.jpg');
      expect(result.score, inInclusiveRange(0, 100));
    });

    test('analyzeFrame breakdown values are 0–100', () async {
      final result = await service.analyzeFrame('/fake/path.jpg');
      expect(result.breakdown, isNotEmpty);
      for (final v in result.breakdown.values) {
        expect(v, inInclusiveRange(0, 100));
      }
    });

    test('analyzeFrame tip is non-empty', () async {
      final result = await service.analyzeFrame('/fake/path.jpg');
      expect(result.tip, isNotEmpty);
    });

    test('analyzeFrame goalZone is null or 0–8', () async {
      final result = await service.analyzeFrame('/x.jpg');
      if (result.goalZone != null) {
        expect(result.goalZone, inInclusiveRange(0, 8));
      }
    });

    test('service auto-initializes on first analyzeFrame call', () async {
      final fresh = MlAnalysisService();
      final result = await fresh.analyzeFrame('/fresh.jpg');
      expect(result.score, inInclusiveRange(0, 100));
      await fresh.dispose();
    });
  });

  // ── ShotCoachingService ───────────────────────────────────────────────────
  group('ShotCoachingService', () {
    late ShotCoachingService service;

    setUp(() => service = ShotCoachingService());

    test('generateReport returns a non-null report', () {
      final report = service.generateReport(
        breakdown: {
          'Balance': 80,
          'Release Point': 75,
          'Follow Through': 70,
          'Body Rotation': 65,
        },
        overallScore: 73,
        discipline: LacrosseDiscipline.mens,
        shotType: ShotType.overhand,
      );

      expect(report.overallScore, equals(73));
      expect(report.discipline, equals(LacrosseDiscipline.mens));
      expect(report.shotType, equals(ShotType.overhand));
    });

    test('generateReport tips are non-empty', () {
      final report = service.generateReport(
        breakdown: {'Balance': 55, 'Release Point': 60},
        overallScore: 57,
        discipline: LacrosseDiscipline.womens,
        shotType: ShotType.sidearm,
      );
      expect(report.tips, isNotEmpty);
    });

    test('generateReport quickCue is non-empty string', () {
      final report = service.generateReport(
        breakdown: {'Balance': 80},
        overallScore: 80,
        discipline: LacrosseDiscipline.mens,
        shotType: null,
      );
      expect(report.quickCue, isNotEmpty);
    });

    test('generateReport with null shotType works (unclassified)', () {
      final report = service.generateReport(
        breakdown: {'Balance': 72},
        overallScore: 72,
        discipline: LacrosseDiscipline.mens,
        shotType: null,
      );
      expect(report.shotType, isNull);
    });

    test('tips are ordered by priority ascending', () {
      final report = service.generateReport(
        breakdown: {
          'Balance': 50,
          'Release Point': 45,
          'Follow Through': 60,
          'Body Rotation': 55,
        },
        overallScore: 52,
        discipline: LacrosseDiscipline.mens,
        shotType: ShotType.overhand,
      );
      for (int i = 1; i < report.tips.length; i++) {
        expect(
          report.tips[i].priority,
          greaterThanOrEqualTo(report.tips[i - 1].priority),
        );
      }
    });
  });

  // ── UserModel ─────────────────────────────────────────────────────────────
  group('UserModel', () {
    test('age is calculated correctly when birthday is today', () {
      final today = DateTime.now();
      final dob = DateTime(today.year - 16, today.month, today.day);
      final user = _makeUser(dob: dob);
      expect(user.age, equals(16));
    });

    test('age has not ticked over when birthday is tomorrow', () {
      final now = DateTime.now();
      final dob = DateTime(now.year - 15, now.month, now.day + 1);
      final user = _makeUser(dob: dob);
      expect(user.age, equals(14));
    });

    test('isMinor flag is stored and readable', () {
      final user = _makeUser(dob: DateTime(2015), isMinor: true);
      expect(user.isMinor, isTrue);
    });

    test('copyWith preserves uid and changes displayName', () {
      final user = _makeUser(dob: DateTime(2005));
      final updated = user.copyWith(displayName: 'New Name');
      expect(updated.displayName, equals('New Name'));
      expect(updated.uid, equals(user.uid));
    });

    test('copyWith changes position', () {
      final user = _makeUser(dob: DateTime(2000));
      final updated = user.copyWith(position: PlayerPosition.goalie);
      expect(updated.position, equals(PlayerPosition.goalie));
    });
  });

  // ── StatsModel ────────────────────────────────────────────────────────────
  group('StatsModel', () {
    test('avgScore returns overallAccuracy * 100', () {
      final stats = _makeStats(totalShots: 10, totalSuccessful: 8);
      expect(stats.avgScore, closeTo(80.0, 0.001));
    });

    test('avgScore is 0 when totalShots is 0', () {
      final stats = _makeStats(totalShots: 0, totalSuccessful: 0);
      expect(stats.avgScore, equals(0.0));
    });

    test('bestScore returns bestAccuracy * 100', () {
      final stats = _makeStats(bestAccuracy: 0.95);
      expect(stats.bestScore, closeTo(95.0, 0.001));
    });

    test('streakDays equals currentStreak', () {
      final stats = StatsModel(
        userId: 'x',
        totalSessions: 0,
        totalShots: 0,
        totalSuccessful: 0,
        lifetimeZoneAccuracy: ZoneAccuracy.empty(),
        bestAccuracy: 0,
        currentStreak: 7,
        longestStreak: 10,
        unlockedAchievements: [],
        lastUpdated: DateTime(2025),
      );
      expect(stats.streakDays, equals(7));
    });

    test('zoneAccuracy has all 9 zone labels', () {
      final stats = _makeStats();
      const labels = ['TL', 'TC', 'TR', 'ML', 'MC', 'MR', 'BL', 'BC', 'BR'];
      for (final label in labels) {
        expect(stats.zoneAccuracy, contains(label));
      }
    });
  });

  // ── Widget: LaxShotLogo ───────────────────────────────────────────────────
  group('LaxShotLogo', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LaxShotLogo(size: 64)),
        ),
      );
      expect(find.byType(LaxShotLogo), findsOneWidget);
    });

    testWidgets('renders label text when showLabel is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LaxShotLogo(size: 48, showLabel: true)),
        ),
      );
      expect(find.text('LaxShot'), findsOneWidget);
    });

    testWidgets('hides label when showLabel is false (default)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LaxShotLogo(size: 48)),
        ),
      );
      expect(find.text('LaxShot'), findsNothing);
    });
  });

  // ── Widget: StatSummaryCard ───────────────────────────────────────────────
  group('StatSummaryCard', () {
    testWidgets('displays label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatSummaryCard(
              label: 'Total Shots',
              value: '42',
              icon: Icons.sports_hockey,
              color: Colors.blue,
            ),
          ),
        ),
      );
      expect(find.text('Total Shots'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(Icons.sports_hockey), findsOneWidget);
    });

    testWidgets('renders dash value without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatSummaryCard(
              label: 'Avg Score',
              value: '--',
              icon: Icons.bar_chart,
              color: Colors.green,
            ),
          ),
        ),
      );
      expect(find.text('--'), findsOneWidget);
    });
  });

  // ── ProviderScope sanity ──────────────────────────────────────────────────
  group('ProviderScope', () {
    testWidgets('renders child without error', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: Text('provider scope ok')),
          ),
        ),
      );
      expect(find.text('provider scope ok'), findsOneWidget);
    });
  });
}
