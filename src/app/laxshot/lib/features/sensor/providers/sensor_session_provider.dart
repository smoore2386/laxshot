import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/ble_constants.dart';
import '../../../data/models/motion_packet.dart';
import '../../../data/models/sensor_shot.dart';
import '../../../data/models/sensor_session_model.dart';
import '../../../data/services/shot_metrics_service.dart';
import 'ble_provider.dart';

enum SensorSessionStatus { idle, active, ended }

class SensorSessionState {
  final SensorSessionStatus status;
  final List<SensorShot> shots;
  final MotionPacket? latestPacket;
  final DateTime? startedAt;
  final int totalPackets;
  final int batteryStartPct;

  const SensorSessionState({
    this.status = SensorSessionStatus.idle,
    this.shots = const [],
    this.latestPacket,
    this.startedAt,
    this.totalPackets = 0,
    this.batteryStartPct = 100,
  });

  SensorSessionState copyWith({
    SensorSessionStatus? status,
    List<SensorShot>? shots,
    MotionPacket? latestPacket,
    DateTime? startedAt,
    int? totalPackets,
    int? batteryStartPct,
  }) {
    return SensorSessionState(
      status: status ?? this.status,
      shots: shots ?? this.shots,
      latestPacket: latestPacket ?? this.latestPacket,
      startedAt: startedAt ?? this.startedAt,
      totalPackets: totalPackets ?? this.totalPackets,
      batteryStartPct: batteryStartPct ?? this.batteryStartPct,
    );
  }

  Duration get elapsed =>
      startedAt != null ? DateTime.now().difference(startedAt!) : Duration.zero;

  SensorShot? get lastShot => shots.isNotEmpty ? shots.last : null;
}

final shotMetricsServiceProvider = Provider<ShotMetricsService>((ref) {
  return ShotMetricsService();
});

final sensorSessionProvider =
    NotifierProvider<SensorSessionNotifier, SensorSessionState>(
        SensorSessionNotifier.new);

class SensorSessionNotifier extends Notifier<SensorSessionState> {
  StreamSubscription<MotionPacket>? _motionSub;
  final List<MotionPacket> _shotBuffer = [];
  bool _wasInShot = false;

  @override
  SensorSessionState build() {
    ref.onDispose(() {
      _motionSub?.cancel();
    });
    return const SensorSessionState();
  }

  /// Start a new sensor session.
  Future<void> startSession() async {
    final bleService = ref.read(bleServiceProvider);

    // Send START_SESSION command to pod (safe if not connected)
    try {
      await bleService.sendCommand(BleConstants.cmdStartSession);
    } catch (_) {
      // Not connected — session still starts for UI preview
    }

    state = SensorSessionState(
      status: SensorSessionStatus.active,
      startedAt: DateTime.now(),
    );

    // Subscribe to motion packets
    _motionSub?.cancel();
    _motionSub = bleService.motionStream.listen(_onPacket);
  }

  /// End the current session.
  Future<void> endSession() async {
    _motionSub?.cancel();

    final bleService = ref.read(bleServiceProvider);
    try {
      await bleService.sendCommand(BleConstants.cmdStopSession);
    } catch (_) {
      // Not connected
    }

    // Finalize any in-progress shot
    if (_shotBuffer.isNotEmpty) {
      _finalizeShot();
    }

    state = state.copyWith(status: SensorSessionStatus.ended);
  }

  /// Reset to idle state for a new session.
  void reset() {
    _motionSub?.cancel();
    _shotBuffer.clear();
    _wasInShot = false;
    state = const SensorSessionState();
  }

  /// Build a SensorSessionModel from the current state.
  SensorSessionModel buildSessionModel({
    required String userId,
    required String deviceId,
  }) {
    final summary = SensorSessionSummary.fromShots(state.shots);
    final duration = state.elapsed;
    final avgRate = state.totalPackets > 0 && duration.inMilliseconds > 0
        ? state.totalPackets / (duration.inMilliseconds / 1000.0)
        : 0.0;

    return SensorSessionModel(
      sessionId: '',
      userId: userId,
      deviceId: deviceId,
      startedAt: state.startedAt ?? DateTime.now(),
      endedAt: DateTime.now(),
      firmwareVersion: '0.1.0',
      shotCount: state.shots.length,
      shots: state.shots,
      metadata: SensorSessionMetadata(
        totalSamples: state.totalPackets,
        avgSampleRateHz: avgRate,
        batteryStartPct: state.batteryStartPct,
        batteryEndPct: state.latestPacket?.batteryPercent ?? 0,
      ),
      summary: summary,
    );
  }

  // ── Private ─────────────────────────────────────────────────────

  void _onPacket(MotionPacket packet) {
    // Record battery at start
    if (state.totalPackets == 0) {
      state = state.copyWith(batteryStartPct: packet.batteryPercent);
    }

    state = state.copyWith(
      latestPacket: packet,
      totalPackets: state.totalPackets + 1,
    );

    // Shot detection: track IN_SHOT flag transitions
    if (packet.inShot) {
      _shotBuffer.add(packet);
      _wasInShot = true;
    } else if (_wasInShot && _shotBuffer.isNotEmpty) {
      // Falling edge: IN_SHOT went 1→0, finalize the shot
      _finalizeShot();
    }
  }

  void _finalizeShot() {
    if (_shotBuffer.isEmpty) return;

    final metrics = ref.read(shotMetricsServiceProvider);
    final shot = metrics.computeShot(List.of(_shotBuffer));

    state = state.copyWith(
      shots: [...state.shots, shot],
    );

    _shotBuffer.clear();
    _wasInShot = false;
  }
}
