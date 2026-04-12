import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sensor_session_model.dart';

final sensorSessionRepositoryProvider =
    Provider<SensorSessionRepository>((ref) {
  return SensorSessionRepository();
});

class SensorSessionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessionsRef(String uid) =>
      _db.collection('users').doc(uid).collection('sensorSessions');

  /// Create a new sensor session. Returns the Firestore document ID.
  Future<String> createSensorSession(
      String uid, SensorSessionModel session) async {
    final doc = await _sessionsRef(uid).add(session.toFirestore());
    return doc.id;
  }

  /// Fetch a single sensor session by ID.
  Future<SensorSessionModel?> getSensorSession(
      String uid, String sessionId) async {
    final doc = await _sessionsRef(uid).doc(sessionId).get();
    if (!doc.exists) return null;
    return SensorSessionModel.fromFirestore(doc);
  }

  /// Stream a single sensor session (real-time updates).
  Stream<SensorSessionModel?> watchSensorSession(
      String uid, String sessionId) {
    return _sessionsRef(uid).doc(sessionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SensorSessionModel.fromFirestore(doc);
    });
  }

  /// Stream recent sensor sessions, ordered by start time descending.
  Stream<List<SensorSessionModel>> watchRecentSensorSessions(
    String uid, {
    int limit = 10,
  }) {
    return _sessionsRef(uid)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SensorSessionModel.fromFirestore(doc))
            .toList());
  }

  /// Export a sensor session's shots to CSV string.
  String exportSessionAsCsv(SensorSessionModel session) {
    final headers = [
      'shot_number',
      'timestamp_ms',
      'peak_accel_g',
      'duration_ms',
      'shot_score',
      'wrist_snap_ms',
      'wrist_snap_dps',
      'release_angle_deg',
      'power_estimate_mph',
      'quat_w',
      'quat_x',
      'quat_y',
      'quat_z',
    ];

    final rows = <List<dynamic>>[headers];
    for (int i = 0; i < session.shots.length; i++) {
      final s = session.shots[i];
      rows.add([
        i + 1,
        s.timestampMs,
        s.peakAccelG.toStringAsFixed(2),
        s.durationMs,
        s.shotScore,
        s.wristSnapMs,
        s.wristSnapDps.toStringAsFixed(1),
        s.releaseAngleDeg.toStringAsFixed(1),
        s.powerEstimateMph.toStringAsFixed(1),
        ...s.quaternionAtRelease.map((q) => q.toStringAsFixed(4)),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Update the user's aggregate stats after saving a sensor session.
  /// Bridges sensor data into the existing stats/summary doc.
  Future<void> updateStatsFromSensorSession(
    String uid,
    SensorSessionModel session,
  ) async {
    final statsRef =
        _db.collection('users').doc(uid).collection('stats').doc('summary');

    await _db.runTransaction((tx) async {
      final snap = await tx.get(statsRef);

      final totalShots = session.shotCount;
      final successfulShots =
          session.shots.where((s) => s.shotScore >= 70).length;

      if (!snap.exists) {
        tx.set(statsRef, {
          'totalSessions': 1,
          'totalShots': totalShots,
          'totalSuccessful': successfulShots,
          'lifetimeZoneAccuracy': List.filled(9, 0.0),
          'bestAccuracy':
              totalShots > 0 ? successfulShots / totalShots : 0.0,
          'currentStreak': 1,
          'longestStreak': 1,
          'unlockedAchievements': ['first_shot'],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        return;
      }

      final data = snap.data()!;
      final prevTotal = data['totalShots'] as int? ?? 0;
      final prevSuccessful = data['totalSuccessful'] as int? ?? 0;
      final prevSessions = data['totalSessions'] as int? ?? 0;
      final prevStreak = data['currentStreak'] as int? ?? 0;
      final prevLongest = data['longestStreak'] as int? ?? 0;
      final prevBest = (data['bestAccuracy'] as num?)?.toDouble() ?? 0.0;
      final lastUpdatedTs = data['lastUpdated'] as Timestamp?;
      final achievements =
          List<String>.from(data['unlockedAchievements'] as List? ?? []);

      final newTotal = prevTotal + totalShots;
      final newSuccessful = prevSuccessful + successfulShots;
      final newSessions = prevSessions + 1;
      final sessionAccuracy =
          totalShots > 0 ? successfulShots / totalShots : 0.0;
      final newBest =
          sessionAccuracy > prevBest ? sessionAccuracy : prevBest;

      // Streak logic
      int newStreak = 1;
      if (lastUpdatedTs != null) {
        final daysDiff =
            DateTime.now().difference(lastUpdatedTs.toDate()).inDays;
        if (daysDiff <= 1) newStreak = prevStreak + 1;
      }
      final newLongest =
          newStreak > prevLongest ? newStreak : prevLongest;

      // Achievement checks
      if (!achievements.contains('first_shot')) {
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

      tx.update(statsRef, {
        'totalSessions': newSessions,
        'totalShots': newTotal,
        'totalSuccessful': newSuccessful,
        'bestAccuracy': newBest,
        'currentStreak': newStreak,
        'longestStreak': newLongest,
        'unlockedAchievements': achievements,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }
}
