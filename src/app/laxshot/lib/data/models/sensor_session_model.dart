import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'sensor_shot.dart';

/// A complete sensor session stored at users/{uid}/sensorSessions/{sessionId}.
class SensorSessionModel {
  final String sessionId;
  final String userId;
  final String deviceId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String firmwareVersion;
  final int shotCount;
  final List<SensorShot> shots;
  final SensorSessionMetadata metadata;
  final SensorSessionSummary? summary;

  const SensorSessionModel({
    required this.sessionId,
    required this.userId,
    required this.deviceId,
    required this.startedAt,
    this.endedAt,
    required this.firmwareVersion,
    required this.shotCount,
    required this.shots,
    required this.metadata,
    this.summary,
  });

  Duration get duration =>
      (endedAt ?? DateTime.now()).difference(startedAt);

  factory SensorSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final shotsList = (data['shots'] as List<dynamic>?)
            ?.map((s) => SensorShot.fromFirestore(s as Map<String, dynamic>))
            .toList() ??
        [];

    return SensorSessionModel(
      sessionId: doc.id,
      userId: data['userId'] as String,
      deviceId: data['deviceId'] as String,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      endedAt: data['endedAt'] != null
          ? (data['endedAt'] as Timestamp).toDate()
          : null,
      firmwareVersion: data['firmwareVersion'] as String? ?? '0.1.0',
      shotCount: data['shotCount'] as int? ?? 0,
      shots: shotsList,
      metadata: SensorSessionMetadata.fromMap(
          data['metadata'] as Map<String, dynamic>? ?? {}),
      summary: data['summary'] != null
          ? SensorSessionSummary.fromMap(
              data['summary'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'deviceId': deviceId,
        'startedAt': Timestamp.fromDate(startedAt),
        if (endedAt != null) 'endedAt': Timestamp.fromDate(endedAt!),
        'firmwareVersion': firmwareVersion,
        'shotCount': shotCount,
        'shots': shots.map((s) => s.toFirestore()).toList(),
        'metadata': metadata.toMap(),
        if (summary != null) 'summary': summary!.toMap(),
      };
}

class SensorSessionMetadata {
  final int totalSamples;
  final double avgSampleRateHz;
  final int batteryStartPct;
  final int batteryEndPct;

  const SensorSessionMetadata({
    required this.totalSamples,
    required this.avgSampleRateHz,
    required this.batteryStartPct,
    required this.batteryEndPct,
  });

  factory SensorSessionMetadata.fromMap(Map<String, dynamic> data) {
    return SensorSessionMetadata(
      totalSamples: data['totalSamples'] as int? ?? 0,
      avgSampleRateHz: (data['avgSampleRateHz'] as num?)?.toDouble() ?? 0,
      batteryStartPct: data['batteryStartPct'] as int? ?? 0,
      batteryEndPct: data['batteryEndPct'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'totalSamples': totalSamples,
        'avgSampleRateHz': avgSampleRateHz,
        'batteryStartPct': batteryStartPct,
        'batteryEndPct': batteryEndPct,
      };
}

class SensorSessionSummary {
  final double avgScore;
  final double avgPowerMph;
  final double avgReleaseAngle;
  final double consistency; // lower = more consistent (stddev of scores)

  const SensorSessionSummary({
    required this.avgScore,
    required this.avgPowerMph,
    required this.avgReleaseAngle,
    required this.consistency,
  });

  factory SensorSessionSummary.fromShots(List<SensorShot> shots) {
    if (shots.isEmpty) {
      return const SensorSessionSummary(
        avgScore: 0,
        avgPowerMph: 0,
        avgReleaseAngle: 0,
        consistency: 0,
      );
    }

    final scores = shots.map((s) => s.shotScore.toDouble()).toList();
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    final avgPower =
        shots.map((s) => s.powerEstimateMph).reduce((a, b) => a + b) /
            shots.length;
    final avgAngle =
        shots.map((s) => s.releaseAngleDeg).reduce((a, b) => a + b) /
            shots.length;

    // Standard deviation of shot scores
    final variance =
        scores.map((s) => (s - avgScore) * (s - avgScore)).reduce((a, b) => a + b) /
            scores.length;
    final stddev = math.sqrt(variance);

    return SensorSessionSummary(
      avgScore: avgScore,
      avgPowerMph: avgPower,
      avgReleaseAngle: avgAngle,
      consistency: stddev,
    );
  }

  factory SensorSessionSummary.fromMap(Map<String, dynamic> data) {
    return SensorSessionSummary(
      avgScore: (data['avgScore'] as num?)?.toDouble() ?? 0,
      avgPowerMph: (data['avgPowerMph'] as num?)?.toDouble() ?? 0,
      avgReleaseAngle: (data['avgReleaseAngle'] as num?)?.toDouble() ?? 0,
      consistency: (data['consistency'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'avgScore': avgScore,
        'avgPowerMph': avgPowerMph,
        'avgReleaseAngle': avgReleaseAngle,
        'consistency': consistency,
      };
}
