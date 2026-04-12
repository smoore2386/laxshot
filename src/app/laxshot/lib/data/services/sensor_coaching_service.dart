import 'dart:math' as math;

import '../models/sensor_shot.dart';
import '../models/shot_classification.dart';
import 'shot_coaching_service.dart';

/// Analyzes patterns across multiple sensor shots and generates coaching
/// feedback using the existing [ShotCoachingService] infrastructure.
class SensorCoachingService {
  final ShotCoachingService _coachingService = ShotCoachingService();

  /// Analyze a list of sensor shots and produce a coaching report.
  /// Requires at least 3 shots for meaningful analysis.
  ShotCoachingReport? analyzeSession(
    List<SensorShot> shots, {
    LacrosseDiscipline discipline = LacrosseDiscipline.mens,
  }) {
    if (shots.length < 3) return null;

    final breakdown = <String, int>{};

    // ── Wrist Snap analysis ───────────────────────────────────────
    final avgSnapMs =
        shots.map((s) => s.wristSnapMs).reduce((a, b) => a + b) /
            shots.length;
    final avgSnapDps =
        shots.map((s) => s.wristSnapDps).reduce((a, b) => a + b) /
            shots.length;

    // Score: fast snap + high DPS = good
    int wristSnapScore;
    if (avgSnapMs <= 80 && avgSnapDps >= 1200) {
      wristSnapScore = 90;
    } else if (avgSnapMs <= 120 && avgSnapDps >= 800) {
      wristSnapScore = 70;
    } else if (avgSnapMs <= 160) {
      wristSnapScore = 50;
    } else {
      wristSnapScore = 30;
    }
    breakdown['Wrist Snap'] = wristSnapScore;

    // ── Release Point / Angle analysis ────────────────────────────
    final avgAngle =
        shots.map((s) => s.releaseAngleDeg).reduce((a, b) => a + b) /
            shots.length;
    final angleVariance = shots
            .map((s) =>
                (s.releaseAngleDeg - avgAngle) *
                (s.releaseAngleDeg - avgAngle))
            .reduce((a, b) => a + b) /
        shots.length;
    final angleStddev = math.sqrt(angleVariance);

    int releasePointScore;
    if (avgAngle >= 45 && avgAngle <= 55 && angleStddev < 5) {
      releasePointScore = 90;
    } else if (avgAngle >= 40 && avgAngle <= 60 && angleStddev < 10) {
      releasePointScore = 70;
    } else if (avgAngle >= 30 && avgAngle <= 70) {
      releasePointScore = 50;
    } else {
      releasePointScore = 30;
    }
    breakdown['Release Point'] = releasePointScore;

    // ── Hip Rotation (proxy: power / peak accel) ──────────────────
    final avgPeakG =
        shots.map((s) => s.peakAccelG).reduce((a, b) => a + b) /
            shots.length;
    int hipRotationScore;
    if (avgPeakG >= 15) {
      hipRotationScore = 90;
    } else if (avgPeakG >= 10) {
      hipRotationScore = 70;
    } else if (avgPeakG >= 7) {
      hipRotationScore = 50;
    } else {
      hipRotationScore = 30;
    }
    breakdown['Hip Rotation'] = hipRotationScore;

    // ── Follow-through (proxy: shot duration — longer = better follow-through) ──
    final avgDurationMs =
        shots.map((s) => s.durationMs).reduce((a, b) => a + b) /
            shots.length;
    int followThroughScore;
    if (avgDurationMs >= 350) {
      followThroughScore = 85;
    } else if (avgDurationMs >= 250) {
      followThroughScore = 70;
    } else if (avgDurationMs >= 150) {
      followThroughScore = 55;
    } else {
      followThroughScore = 35;
    }
    breakdown['Follow-through'] = followThroughScore;

    // ── Balance (proxy: consistency — low score stddev = good balance) ──
    final scores = shots.map((s) => s.shotScore.toDouble()).toList();
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    final scoreVariance =
        scores.map((s) => (s - avgScore) * (s - avgScore)).reduce((a, b) => a + b) /
            scores.length;
    final scoreStddev = math.sqrt(scoreVariance);

    int balanceScore;
    if (scoreStddev < 8) {
      balanceScore = 90;
    } else if (scoreStddev < 15) {
      balanceScore = 70;
    } else if (scoreStddev < 25) {
      balanceScore = 50;
    } else {
      balanceScore = 30;
    }
    breakdown['Balance'] = balanceScore;

    // ── Fill remaining categories with reasonable defaults ─────────
    breakdown['Shoulder Turn'] = ((hipRotationScore + wristSnapScore) / 2).round();
    breakdown['Footwork'] = balanceScore; // correlated
    breakdown['Stick Protection'] = 75; // can't measure from IMU alone

    // Composite
    final overallScore = avgScore.round().clamp(0, 100);

    return _coachingService.generateReport(
      breakdown: breakdown,
      overallScore: overallScore,
      discipline: discipline,
    );
  }

  /// Quick diagnosis string for real-time coaching hint during live session.
  String? quickDiagnosis(List<SensorShot> shots) {
    if (shots.length < 5) return null;

    final recent = shots.length > 10 ? shots.sublist(shots.length - 10) : shots;

    // Check for common patterns
    final lateSnaps =
        recent.where((s) => s.wristSnapMs > 120).length;
    final badAngles =
        recent.where((s) => s.releaseAngleDeg < 40 || s.releaseAngleDeg > 60).length;
    final lowPower =
        recent.where((s) => s.peakAccelG < 10).length;

    if (lateSnaps > recent.length * 0.6) {
      return 'Wrist snap is late on $lateSnaps/${recent.length} shots. '
          'Try snapping earlier — aim for under 80ms.';
    }
    if (badAngles > recent.length * 0.6) {
      return 'Release angle is off on $badAngles/${recent.length} shots. '
          'Aim for 45-55 degrees at release.';
    }
    if (lowPower > recent.length * 0.6) {
      return 'Power is low on $lowPower/${recent.length} shots. '
          'Drive your hips and snap through the ball.';
    }

    return null;
  }
}
