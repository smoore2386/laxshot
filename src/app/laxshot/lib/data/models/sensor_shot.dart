import 'motion_packet.dart';

/// A single detected shot with raw packets and derived metrics.
class SensorShot {
  /// Timestamp of the shot start (ms since pod boot).
  final int timestampMs;

  /// Peak acceleration magnitude during the shot (g).
  final double peakAccelG;

  /// Quaternion at the release point (moment IN_SHOT drops).
  final List<double> quaternionAtRelease; // [w, x, y, z]

  /// Duration of the shot capture window (ms).
  final int durationMs;

  /// Composite shot score (0-100).
  final int shotScore;

  /// Time from acceleration ramp start to peak gyro-Z (ms).
  final int wristSnapMs;

  /// Peak gyro-Z magnitude during the shot (deg/s).
  final double wristSnapDps;

  /// Stick head angle at release derived from quaternion (degrees).
  final double releaseAngleDeg;

  /// Estimated shot power (mph).
  final double powerEstimateMph;

  /// Raw motion packets captured during the shot (for 3D replay).
  final List<MotionPacket> packets;

  const SensorShot({
    required this.timestampMs,
    required this.peakAccelG,
    required this.quaternionAtRelease,
    required this.durationMs,
    required this.shotScore,
    required this.wristSnapMs,
    required this.wristSnapDps,
    required this.releaseAngleDeg,
    required this.powerEstimateMph,
    required this.packets,
  });

  /// Serialize for Firestore (excludes raw packets to save space).
  Map<String, dynamic> toFirestore() => {
        'timestampMs': timestampMs,
        'peakAccelG': peakAccelG,
        'quaternion': quaternionAtRelease,
        'durationMs': durationMs,
        'shotScore': shotScore,
        'wristSnapMs': wristSnapMs,
        'wristSnapDps': wristSnapDps,
        'releaseAngleDeg': releaseAngleDeg,
        'powerEstimateMph': powerEstimateMph,
      };

  factory SensorShot.fromFirestore(Map<String, dynamic> data) {
    return SensorShot(
      timestampMs: data['timestampMs'] as int,
      peakAccelG: (data['peakAccelG'] as num).toDouble(),
      quaternionAtRelease: List<double>.from(
          (data['quaternion'] as List).map((e) => (e as num).toDouble())),
      durationMs: data['durationMs'] as int,
      shotScore: data['shotScore'] as int,
      wristSnapMs: data['wristSnapMs'] as int,
      wristSnapDps: (data['wristSnapDps'] as num).toDouble(),
      releaseAngleDeg: (data['releaseAngleDeg'] as num).toDouble(),
      powerEstimateMph: (data['powerEstimateMph'] as num).toDouble(),
      packets: const [], // Raw packets not stored in Firestore
    );
  }
}
