import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/motion_packet.dart';
import 'ble_service.dart';

/// A fake BLE service that replays synthetic sensor data so the full sensor
/// flow can be tested without real BLE hardware.
///
/// Simulates a repeating lacrosse shot cycle at ~50 Hz:
///   0.0–2.0 s  Idle          (gravity only, ~1 g on Z)
///   2.0–3.0 s  Wind-up       (increasing gyro / slight accel ramp)
///   3.0–3.2 s  Shot          (15–25 g accel spike, high gyro)
///   3.2–4.0 s  Follow-through (decaying back toward idle)
///   4.0–5.0 s  Idle          (settle)
///   — then repeat —
class FakeBleService extends BleService {
  // ── Internal state ───────────────────────────────────────────────
  final _connectionCtrl = StreamController<BleConnectionState>.broadcast();
  final _motionCtrl = StreamController<MotionPacket>.broadcast();

  Timer? _emitTimer;
  BleConnectionState _state = BleConnectionState.disconnected;
  int _tickMs = 0; // virtual pod clock
  bool _disposed = false;

  static const int _intervalMs = 20; // 50 Hz
  static const int _cycleMs = 5000; // 5-second repeating cycle
  static const int _batteryPercent = 87; // cosmetic constant

  // ── Public API (overrides) ───────────────────────────────────────

  @override
  Stream<BleConnectionState> get connectionState => _connectionCtrl.stream;

  @override
  Stream<MotionPacket> get motionStream => _motionCtrl.stream;

  @override
  BluetoothDevice? get connectedDevice => null; // no real device

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Stream<List<ScanResult>> startScan() async* {
    // Brief simulated scan delay, then yield an empty list (no real device
    // objects available, but the UI gets a non-null event).
    await Future<void>.delayed(const Duration(milliseconds: 500));
    yield <ScanResult>[];
  }

  @override
  Future<void> stopScan() async {
    // no-op
  }

  /// Simulate connection: transitions to connecting, waits briefly, then
  /// transitions to connected and begins emitting motion data.
  @override
  Future<void> connect(BluetoothDevice device) async {
    _setState(BleConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (_disposed) return;
    _setState(BleConnectionState.connected);
    _startEmitting();
  }

  /// Convenience overload so callers without a real [BluetoothDevice] can
  /// trigger the fake connection (e.g. from a "Connect Demo Sensor" button).
  Future<void> connectFake() async {
    _setState(BleConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (_disposed) return;
    _setState(BleConnectionState.connected);
    _startEmitting();
  }

  @override
  Future<void> disconnect() async {
    _stopEmitting();
    _setState(BleConnectionState.disconnected);
  }

  @override
  Future<void> sendCommand(int command) async {
    // no-op
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _stopEmitting();
    await _connectionCtrl.close();
    await _motionCtrl.close();
  }

  // ── Private helpers ──────────────────────────────────────────────

  void _setState(BleConnectionState s) {
    _state = s;
    if (!_connectionCtrl.isClosed) {
      _connectionCtrl.add(s);
    }
  }

  void _startEmitting() {
    _tickMs = 0;
    _emitTimer?.cancel();
    _emitTimer = Timer.periodic(
      const Duration(milliseconds: _intervalMs),
      (_) => _emitPacket(),
    );
  }

  void _stopEmitting() {
    _emitTimer?.cancel();
    _emitTimer = null;
  }

  void _emitPacket() {
    if (_motionCtrl.isClosed) return;

    final packet = _synthesize(_tickMs);
    _motionCtrl.add(packet);
    _tickMs += _intervalMs;
  }

  /// Build a [MotionPacket] for the given virtual timestamp, following a
  /// realistic lacrosse shot motion profile.
  MotionPacket _synthesize(int ms) {
    final t = (ms % _cycleMs) / 1000.0; // position within cycle (seconds)

    double accelX, accelY, accelZ;
    double gyroX, gyroY, gyroZ;
    bool inShot = false;

    if (t < 2.0) {
      // ── Idle: stick at rest, gravity on Z ──
      accelX = _jitter(0.02);
      accelY = _jitter(0.02);
      accelZ = 1.0 + _jitter(0.02);
      gyroX = _jitter(2.0);
      gyroY = _jitter(2.0);
      gyroZ = _jitter(2.0);
    } else if (t < 3.0) {
      // ── Wind-up: player draws stick back ──
      final phase = (t - 2.0); // 0 → 1 over 1 second
      accelX = 0.5 * phase + _jitter(0.05);
      accelY = 0.3 * phase + _jitter(0.05);
      accelZ = 1.0 + 0.5 * phase + _jitter(0.05);
      gyroX = 80.0 * phase + _jitter(5.0);
      gyroY = 40.0 * phase + _jitter(5.0);
      gyroZ = 200.0 * phase + _jitter(10.0); // wrist starting to rotate
    } else if (t < 3.2) {
      // ── Shot: explosive acceleration spike ──
      inShot = true;
      final phase = (t - 3.0) / 0.2; // 0 → 1 over 200 ms
      // Bell-curve-ish profile peaking in the middle
      final bell = math.sin(phase * math.pi);
      accelX = 5.0 * bell + _jitter(0.3);
      accelY = 3.0 * bell + _jitter(0.3);
      accelZ = 1.0 + 20.0 * bell + _jitter(0.5); // peak ~21 g
      gyroX = 150.0 + 350.0 * bell + _jitter(15.0);
      gyroY = 100.0 + 200.0 * bell + _jitter(10.0);
      gyroZ = 400.0 + 1200.0 * bell + _jitter(20.0); // wrist snap peak ~1600 deg/s
    } else if (t < 4.0) {
      // ── Follow-through: decaying motion ──
      final phase = (t - 3.2) / 0.8; // 0 → 1 over 800 ms
      final decay = 1.0 - phase;
      accelX = 2.0 * decay + _jitter(0.1);
      accelY = 1.0 * decay + _jitter(0.1);
      accelZ = 1.0 + 3.0 * decay + _jitter(0.1);
      gyroX = 80.0 * decay + _jitter(5.0);
      gyroY = 50.0 * decay + _jitter(5.0);
      gyroZ = 200.0 * decay + _jitter(10.0);
    } else {
      // ── Post-shot idle (settle) ──
      accelX = _jitter(0.03);
      accelY = _jitter(0.03);
      accelZ = 1.0 + _jitter(0.03);
      gyroX = _jitter(3.0);
      gyroY = _jitter(3.0);
      gyroZ = _jitter(3.0);
    }

    // Quaternion: simple rotation about Z that follows stick motion.
    // During idle the stick is upright (identity quat); during the shot
    // we tilt it forward to simulate a release angle around 45°.
    final tiltRad = inShot ? 0.4 : 0.0; // ~23° tilt during shot
    final quatW = math.cos(tiltRad / 2);
    final quatX = 0.0;
    final quatY = math.sin(tiltRad / 2);
    final quatZ = 0.0;

    return MotionPacket(
      accelX: accelX,
      accelY: accelY,
      accelZ: accelZ,
      gyroX: gyroX,
      gyroY: gyroY,
      gyroZ: gyroZ,
      quatW: quatW,
      quatX: quatX,
      quatY: quatY,
      quatZ: quatZ,
      batteryPercent: _batteryPercent,
      inShot: inShot,
      sessionActive: _state == BleConnectionState.connected,
      timestampMs: ms,
    );
  }

  // Small random noise to make traces look realistic.
  static final _rng = math.Random();
  static double _jitter(double amplitude) =>
      (_rng.nextDouble() * 2.0 - 1.0) * amplitude;
}
