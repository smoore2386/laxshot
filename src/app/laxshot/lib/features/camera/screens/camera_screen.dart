import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../analysis/providers/ml_provider.dart';

enum RecordingMode { player, goalie }

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  RecordingMode _mode = RecordingMode.player;
  bool _isRecording = false;
  bool _isCountingDown = false;
  int _countdown = 3;
  int _recordingSeconds = 0;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    if (mounted) {
      setState(() => _controller = controller);
    }
  }

  void _startCountdown() {
    if (_isRecording || _isCountingDown) return;
    setState(() {
      _isCountingDown = true;
      _countdown = 3;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 1) {
        t.cancel();
        setState(() => _isCountingDown = false);
        _startRecording();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.startVideoRecording();
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingSeconds++);
      if (_recordingSeconds >= 30) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    if (_controller == null || !_isRecording) return;

    final videoFile = await _controller!.stopVideoRecording();
    setState(() => _isRecording = false);

    // Capture a still frame for ML analysis (lighter than full video inference)
    String? framePath;
    try {
      final image = await _controller!.takePicture();
      framePath = image.path;
    } catch (_) {
      // Fall back to video file path if still capture fails
      framePath = videoFile.path;
    }

    // Kick off ML analysis before navigating — provider handles async loading state
    if (mounted) {
      ref.read(analysisNotifierProvider.notifier).analyze(framePath);
      final sessionId = 'new_${DateTime.now().millisecondsSinceEpoch}';
      context.push(AppRoutes.results.replaceAll(':sessionId', sessionId));
    }
  }

  String get _formattedTime {
    final m = _recordingSeconds ~/ 60;
    final s = _recordingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => context.pop(),
                  ),
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, color: Colors.white, size: 10),
                          const SizedBox(width: 6),
                          Text(_formattedTime,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                    onPressed: () async {
                      final cameras = await availableCameras();
                      if (cameras.length < 2) return;
                      final current = _controller?.description;
                      final next = cameras.firstWhere(
                        (c) => c.lensDirection != current?.lensDirection,
                        orElse: () => cameras.first,
                      );
                      final newController = CameraController(next, ResolutionPreset.high, enableAudio: false);
                      await newController.initialize();
                      await _controller?.dispose();
                      if (mounted) setState(() => _controller = newController);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Countdown overlay
          if (_isCountingDown)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.5, end: 0.8),
                duration: const Duration(milliseconds: 800),
                builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode toggle
                    if (!_isRecording && !_isCountingDown)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSizes.lg),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ModeButton(
                              label: '🏒  Player',
                              selected: _mode == RecordingMode.player,
                              onTap: () => setState(() => _mode = RecordingMode.player),
                            ),
                            _ModeButton(
                              label: '🥅  Goalie',
                              selected: _mode == RecordingMode.goalie,
                              onTap: () => setState(() => _mode = RecordingMode.goalie),
                            ),
                          ],
                        ),
                      ),

                    // Record button
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startCountdown,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isRecording ? 72 : 80,
                        height: _isRecording ? 72 : 80,
                        decoration: BoxDecoration(
                          shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: _isRecording ? BorderRadius.circular(16) : null,
                          color: Colors.red,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _isRecording
                            ? const Icon(Icons.stop, color: Colors.white, size: 32)
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      _isRecording ? 'Tap to stop' : 'Tap to record',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
