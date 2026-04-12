import 'dart:math' as math;
import 'dart:typed_data';

/// A single 48-byte BLE notification from the LaxPod sensor.
///
/// Packet format (little-endian):
///   [0-11]   float32×3  accelerometer (x, y, z) in g
///   [12-23]  float32×3  gyroscope (x, y, z) in deg/s
///   [24-39]  float32×4  quaternion (w, x, y, z)
///   [40]     uint8      battery percentage (0-100)
///   [41]     uint8      flags (bit 0: IN_SHOT, bit 1: SESSION_ACTIVE)
///   [42-45]  uint32     timestamp (ms since pod boot)
///   [46-47]  uint16     reserved
class MotionPacket {
  final double accelX, accelY, accelZ; // g
  final double gyroX, gyroY, gyroZ; // deg/s
  final double quatW, quatX, quatY, quatZ; // unit quaternion
  final int batteryPercent; // 0-100
  final bool inShot;
  final bool sessionActive;
  final int timestampMs; // ms since pod boot

  const MotionPacket({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.quatW,
    required this.quatX,
    required this.quatY,
    required this.quatZ,
    required this.batteryPercent,
    required this.inShot,
    required this.sessionActive,
    required this.timestampMs,
  });

  factory MotionPacket.fromBytes(List<int> bytes) {
    assert(bytes.length >= 48, 'MotionPacket requires 48 bytes, got ${bytes.length}');
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    return MotionPacket(
      accelX: data.getFloat32(0, Endian.little),
      accelY: data.getFloat32(4, Endian.little),
      accelZ: data.getFloat32(8, Endian.little),
      gyroX: data.getFloat32(12, Endian.little),
      gyroY: data.getFloat32(16, Endian.little),
      gyroZ: data.getFloat32(20, Endian.little),
      quatW: data.getFloat32(24, Endian.little),
      quatX: data.getFloat32(28, Endian.little),
      quatY: data.getFloat32(32, Endian.little),
      quatZ: data.getFloat32(36, Endian.little),
      batteryPercent: data.getUint8(40),
      inShot: (data.getUint8(41) & 0x01) != 0,
      sessionActive: (data.getUint8(41) & 0x02) != 0,
      timestampMs: data.getUint32(42, Endian.little),
    );
  }

  /// Total acceleration magnitude in g.
  double get accelMagnitude =>
      math.sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);

  /// Total gyroscope magnitude in deg/s.
  double get gyroMagnitude =>
      math.sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);

  /// Gyro Z-axis absolute value (primary wrist snap indicator).
  double get gyroZAbs => gyroZ.abs();

  /// Pitch angle derived from quaternion (stick head release angle) in degrees.
  double get pitchDeg {
    final sinP = 2.0 * (quatW * quatY - quatZ * quatX);
    // Clamp to avoid NaN from floating point imprecision
    final clampedSinP = sinP.clamp(-1.0, 1.0);
    return math.asin(clampedSinP) * (180.0 / math.pi);
  }

  /// Serialize to a list for CSV export.
  List<dynamic> toCsvRow() => [
        timestampMs,
        accelX,
        accelY,
        accelZ,
        accelMagnitude,
        gyroX,
        gyroY,
        gyroZ,
        gyroMagnitude,
        quatW,
        quatX,
        quatY,
        quatZ,
        pitchDeg,
        batteryPercent,
        inShot ? 1 : 0,
      ];

  static List<String> get csvHeaders => [
        'timestamp_ms',
        'accel_x_g',
        'accel_y_g',
        'accel_z_g',
        'accel_mag_g',
        'gyro_x_dps',
        'gyro_y_dps',
        'gyro_z_dps',
        'gyro_mag_dps',
        'quat_w',
        'quat_x',
        'quat_y',
        'quat_z',
        'pitch_deg',
        'battery_pct',
        'in_shot',
      ];
}
