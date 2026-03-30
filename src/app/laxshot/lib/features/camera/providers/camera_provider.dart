import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/session_model.dart';

enum RecordingState { idle, countdown, recording, stopping, done }

class CameraState {
  final CameraController? controller;
  final List<CameraDescription> cameras;
  final RecordingState recordingState;
  final SessionMode mode;
  final int countdown;
  final Duration elapsed;
  final String? error;
  final String? recordedPath;

  const CameraState({
    this.controller,
    this.cameras = const [],
    this.recordingState = RecordingState.idle,
    this.mode = SessionMode.player,
    this.countdown = 3,
    this.elapsed = Duration.zero,
    this.error,
    this.recordedPath,
  });

  bool get isRecording => recordingState == RecordingState.recording;
  bool get isBusy =>
      recordingState == RecordingState.countdown ||
      recordingState == RecordingState.stopping;

  CameraState copyWith({
    CameraController? controller,
    List<CameraDescription>? cameras,
    RecordingState? recordingState,
    SessionMode? mode,
    int? countdown,
    Duration? elapsed,
    String? error,
    String? recordedPath,
  }) =>
      CameraState(
        controller: controller ?? this.controller,
        cameras: cameras ?? this.cameras,
        recordingState: recordingState ?? this.recordingState,
        mode: mode ?? this.mode,
        countdown: countdown ?? this.countdown,
        elapsed: elapsed ?? this.elapsed,
        error: error,
        recordedPath: recordedPath ?? this.recordedPath,
      );
}

class CameraNotifier extends AsyncNotifier<CameraState> {
  Timer? _elapsedTimer;
  Timer? _countdownTimer;

  @override
  Future<CameraState> build() async {
    ref.onDispose(() {
      _elapsedTimer?.cancel();
      _countdownTimer?.cancel();
      state.valueOrNull?.controller?.dispose();
    });
    return await _initCamera();
  }

  Future<CameraState> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return const CameraState(error: 'No cameras available on this device.');
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await controller.initialize();
      return CameraState(controller: controller, cameras: cameras);
    } catch (e) {
      return CameraState(error: 'Camera initialization failed: $e');
    }
  }

  void toggleMode() {
    final current = state.valueOrNull;
    if (current == null) return;
    final newMode = current.mode == SessionMode.player
        ? SessionMode.goalie
        : SessionMode.player;
    state = AsyncData(current.copyWith(mode: newMode));
  }

  Future<void> startRecording() async {
    final current = state.valueOrNull;
    if (current == null || current.controller == null) return;
    if (current.isBusy || current.isRecording) return;

    // Begin countdown 3-2-1
    state = AsyncData(current.copyWith(
      recordingState: RecordingState.countdown,
      countdown: 3,
    ));

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      final s = state.valueOrNull;
      if (s == null) {
        t.cancel();
        return;
      }
      final next = s.countdown - 1;
      if (next > 0) {
        state = AsyncData(s.copyWith(countdown: next));
      } else {
        t.cancel();
        await _beginActualRecording();
      }
    });
  }

  Future<void> _beginActualRecording() async {
    final current = state.valueOrNull;
    if (current?.controller == null) return;
    try {
      await current!.controller!.startVideoRecording();
      state = AsyncData(current.copyWith(
        recordingState: RecordingState.recording,
        elapsed: Duration.zero,
      ));
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final s = state.valueOrNull;
        if (s == null || !s.isRecording) return;
        state = AsyncData(s.copyWith(
          elapsed: Duration(seconds: s.elapsed.inSeconds + 1),
        ));
      });
    } catch (e) {
      state = AsyncData(current!.copyWith(
        recordingState: RecordingState.idle,
        error: 'Recording failed: $e',
      ));
    }
  }

  Future<String?> stopRecording() async {
    _elapsedTimer?.cancel();
    final current = state.valueOrNull;
    if (current?.controller == null || !current!.isRecording) return null;

    state = AsyncData(current.copyWith(recordingState: RecordingState.stopping));
    try {
      final file = await current.controller!.stopVideoRecording();
      state = AsyncData(current.copyWith(
        recordingState: RecordingState.done,
        recordedPath: file.path,
      ));
      return file.path;
    } catch (e) {
      state = AsyncData(current.copyWith(
        recordingState: RecordingState.idle,
        error: 'Failed to stop recording: $e',
      ));
      return null;
    }
  }

  void resetToIdle() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      recordingState: RecordingState.idle,
      elapsed: Duration.zero,
      countdown: 3,
    ));
  }
}

final cameraNotifierProvider =
    AsyncNotifierProvider<CameraNotifier, CameraState>(CameraNotifier.new);
