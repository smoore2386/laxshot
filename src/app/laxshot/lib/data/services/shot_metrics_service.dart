import 'dart:math' as math;

import '../models/motion_packet.dart';
import '../models/sensor_shot.dart';

/// Pure computation service — derives shot metrics from raw motion packets.
/// No I/O, no state, no dependencies.
class ShotMetricsService {
  // ── Scoring weights ──────────────────────────────────────────────
  static const double _powerWeight = 0.40; // 40% of shot score
  static const double _snapWeight = 0.30; // 30%
  static const double _angleWeight = 0.30; // 30%

  // ── Thresholds ───────────────────────────────────────────────────
  static const double _elitePeakAccelG = 20.0; // 20g = elite shot
  static const double _eliteSnapDps = 1500.0; // deg/s
  static const int _idealSnapMs = 80; // ms — fast snap target
  static const double _idealAngleMin = 45.0; // degrees
  static const double _idealAngleMax = 55.0;
  static const double _angleToleranceDeg = 20.0; // falloff zone

  // ── Power estimate calibration ──────────────────────────────────
  static const double _powerCalibrationK = 4.5;

  /// Compute all derived metrics for a single shot from its captured packets.
  ///
  /// [packets] — all MotionPackets captured while IN_SHOT was high.
  /// Returns a fully populated [SensorShot].
  SensorShot computeShot(List<MotionPacket> packets) {
    if (packets.isEmpty) {
      return SensorShot(
        timestampMs: 0,
        peakAccelG: 0,
        quaternionAtRelease: [1, 0, 0, 0],
        durationMs: 0,
        shotScore: 0,
        wristSnapMs: 0,
        wristSnapDps: 0,
        releaseAngleDeg: 0,
        powerEstimateMph: 0,
        packets: packets,
      );
    }

    final first = packets.first;
    final last = packets.last;
    final durationMs = last.timestampMs - first.timestampMs;

    // ── Peak acceleration ──────────────────────────────────────────
    double peakAccelG = 0;
    int peakAccelIdx = 0;
    for (int i = 0; i < packets.length; i++) {
      final mag = packets[i].accelMagnitude;
      if (mag > peakAccelG) {
        peakAccelG = mag;
        peakAccelIdx = i;
      }
    }

    // ── Wrist snap: peak gyro-Z timing ─────────────────────────────
    double peakGyroZ = 0;
    int peakGyroZIdx = 0;
    for (int i = 0; i < packets.length; i++) {
      final gz = packets[i].gyroZAbs;
      if (gz > peakGyroZ) {
        peakGyroZ = gz;
        peakGyroZIdx = i;
      }
    }

    // Snap timing = time from acceleration ramp start to gyro-Z peak
    // Use the accel peak as proxy for ramp start
    final accelPeakTs = packets[peakAccelIdx].timestampMs;
    final gyroPeakTs = packets[peakGyroZIdx].timestampMs;
    final wristSnapMs = (gyroPeakTs - accelPeakTs).abs();

    // ── Release angle from quaternion at end of shot ────────────────
    final releaseAngleDeg = last.pitchDeg.abs();
    final quaternionAtRelease = [
      last.quatW,
      last.quatX,
      last.quatY,
      last.quatZ,
    ];

    // ── Power estimate (mph) ────────────────────────────────────────
    final durationSec = math.max(durationMs / 1000.0, 0.01);
    final powerEstimateMph = _powerCalibrationK * peakAccelG * math.sqrt(durationSec);

    // ── Composite shot score (0-100) ────────────────────────────────
    final powerScore = _scorePower(peakAccelG);
    final snapScore = _scoreWristSnap(wristSnapMs, peakGyroZ);
    final angleScore = _scoreReleaseAngle(releaseAngleDeg);
    final shotScore = (powerScore + snapScore + angleScore).round().clamp(0, 100);

    return SensorShot(
      timestampMs: first.timestampMs,
      peakAccelG: peakAccelG,
      quaternionAtRelease: quaternionAtRelease,
      durationMs: durationMs,
      shotScore: shotScore,
      wristSnapMs: wristSnapMs,
      wristSnapDps: peakGyroZ,
      releaseAngleDeg: releaseAngleDeg,
      powerEstimateMph: powerEstimateMph,
      packets: packets,
    );
  }

  // ── Scoring sub-functions ──────────────────────────────────────────

  double _scorePower(double peakAccelG) {
    final normalized = (peakAccelG / _elitePeakAccelG).clamp(0.0, 1.0);
    return normalized * _powerWeight * 100;
  }

  double _scoreWristSnap(int snapMs, double snapDps) {
    // Score gyro magnitude (higher = better snap)
    final dpsNorm = (snapDps / _eliteSnapDps).clamp(0.0, 1.0);
    // Score timing (lower = better — snappier)
    final timingNorm = snapMs <= _idealSnapMs
        ? 1.0
        : (1.0 - ((snapMs - _idealSnapMs) / 200.0)).clamp(0.0, 1.0);
    // Blend: 60% magnitude, 40% timing
    final combined = dpsNorm * 0.6 + timingNorm * 0.4;
    return combined * _snapWeight * 100;
  }

  double _scoreReleaseAngle(double angleDeg) {
    if (angleDeg >= _idealAngleMin && angleDeg <= _idealAngleMax) {
      return _angleWeight * 100; // Perfect range
    }
    // Linear falloff outside ideal range
    final dist = angleDeg < _idealAngleMin
        ? _idealAngleMin - angleDeg
        : angleDeg - _idealAngleMax;
    final penalty = (dist / _angleToleranceDeg).clamp(0.0, 1.0);
    return (1.0 - penalty) * _angleWeight * 100;
  }
}
