import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_model.dart';
import '../repositories/session_repository.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(ref.watch(sessionRepositoryProvider));
});

/// Bridges the gap between ML analysis results and persistent storage.
/// Creates sessions, updates the user's aggregate stats doc.
class SessionService {
  final SessionRepository _sessionRepo;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  SessionService(this._sessionRepo);

  /// Persist a completed analysis as a new session and update aggregate stats.
  ///
  /// [uid] — Firebase Auth user ID
  /// [mode] — player or goalie
  /// [durationSeconds] — recording length
  /// [overallScore] — 0-100 from the analysis engine
  /// [goalZone] — predicted target zone (0-8) or null
  /// [breakdown] — per-category scores, e.g. {"Balance": 85, ...}
  Future<String> saveAnalysis({
    required String uid,
    required SessionMode mode,
    required int durationSeconds,
    required int overallScore,
    int? goalZone,
    Map<String, int> breakdown = const {},
  }) async {
    // Build zone accuracy from the single goal-zone target.
    // In a single-shot analysis the "accuracy" for the targeted zone is the
    // normalised overall score; other zones stay at 0.
    final zones = List<double>.filled(9, 0.0);
    if (goalZone != null && goalZone >= 0 && goalZone < 9) {
      zones[goalZone] = overallScore / 100.0;
    }

    final session = SessionModel(
      sessionId: '', // Firestore will assign
      userId: uid,
      mode: mode,
      recordedAt: DateTime.now(),
      duration: Duration(seconds: durationSeconds),
      totalShots: 1,
      successfulShots: overallScore >= 70 ? 1 : 0,
      zoneAccuracy: ZoneAccuracy(accuracyByZone: zones),
      analysisComplete: true,
    );

    final sessionId = await _sessionRepo.createSession(uid, session);

    // Update aggregate stats in a transaction to avoid races.
    await _updateStats(uid, session);

    return sessionId;
  }

  /// Atomically update the user's aggregate stats document.
  Future<void> _updateStats(String uid, SessionModel session) async {
    final statsRef =
        _db.collection('users').doc(uid).collection('stats').doc('summary');

    await _db.runTransaction((tx) async {
      final snap = await tx.get(statsRef);

      if (!snap.exists) {
        // First session ever — create the stats doc.
        tx.set(statsRef, _initialStats(uid, session));
        return;
      }

      final data = snap.data()!;
      final prevTotal = data['totalShots'] as int? ?? 0;
      final prevSuccessful = data['totalSuccessful'] as int? ?? 0;
      final prevSessions = data['totalSessions'] as int? ?? 0;
      final prevBest = (data['bestAccuracy'] as num?)?.toDouble() ?? 0.0;
      final prevStreak = data['currentStreak'] as int? ?? 0;
      final prevLongest = data['longestStreak'] as int? ?? 0;
      final lastUpdatedTs = data['lastUpdated'] as Timestamp?;
      final prevZones = List<double>.from(
          (data['lifetimeZoneAccuracy'] as List?)?.map((e) => (e as num).toDouble()) ??
              List.filled(9, 0.0));
      final achievements =
          List<String>.from(data['unlockedAchievements'] as List? ?? []);

      final newTotal = prevTotal + session.totalShots;
      final newSuccessful = prevSuccessful + session.successfulShots;
      final newSessions = prevSessions + 1;
      final sessionAccuracy = session.accuracy;
      final newBest = math.max(prevBest, sessionAccuracy);

      // Streak: if last session was yesterday or today, continue; else reset.
      int newStreak = 1;
      if (lastUpdatedTs != null) {
        final lastDate = lastUpdatedTs.toDate();
        final daysDiff = DateTime.now().difference(lastDate).inDays;
        if (daysDiff <= 1) {
          newStreak = prevStreak + 1;
        }
      }
      final newLongest = math.max(prevLongest, newStreak);

      // Merge zone accuracy (running average).
      final newZones = List<double>.generate(9, (i) {
        final sessionVal = session.zoneAccuracy.accuracyByZone[i];
        if (sessionVal == 0.0 && prevZones[i] == 0.0) return 0.0;
        // Weighted average: old data weighted by session count, new by 1.
        return ((prevZones[i] * prevSessions) + sessionVal) / newSessions;
      });

      // Check achievements.
      if (newSessions >= 1 && !achievements.contains('first_shot')) {
        achievements.add('first_shot');
      }
      if (sessionAccuracy >= 0.9 && !achievements.contains('sharpshooter')) {
        achievements.add('sharpshooter');
      }
      if (newStreak >= 7 && !achievements.contains('streak_7')) {
        achievements.add('streak_7');
      }
      if (newTotal >= 100 && !achievements.contains('century')) {
        achievements.add('century');
      }
      if (newZones.every((z) => z > 0) && !achievements.contains('all_zones')) {
        achievements.add('all_zones');
      }
      // 'consistent' = 10+ sessions with avg accuracy >= 70%
      if (newSessions >= 10 &&
          newTotal > 0 &&
          (newSuccessful / newTotal) >= 0.7 &&
          !achievements.contains('consistent')) {
        achievements.add('consistent');
      }

      tx.update(statsRef, {
        'totalSessions': newSessions,
        'totalShots': newTotal,
        'totalSuccessful': newSuccessful,
        'lifetimeZoneAccuracy': newZones,
        'bestAccuracy': newBest,
        'currentStreak': newStreak,
        'longestStreak': newLongest,
        'unlockedAchievements': achievements,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Map<String, dynamic> _initialStats(String uid, SessionModel session) {
    final achievements = <String>['first_shot'];
    if (session.accuracy >= 0.9) achievements.add('sharpshooter');

    return {
      'totalSessions': 1,
      'totalShots': session.totalShots,
      'totalSuccessful': session.successfulShots,
      'lifetimeZoneAccuracy': session.zoneAccuracy.toJson(),
      'bestAccuracy': session.accuracy,
      'currentStreak': 1,
      'longestStreak': 1,
      'unlockedAchievements': achievements,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
