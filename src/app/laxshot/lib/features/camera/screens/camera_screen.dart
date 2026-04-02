import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/session_model.dart';
import '../../../data/models/shot_classification.dart';
import '../../../data/services/session_service.dart';
import '../../analysis/providers/ml_provider.dart';
import '../../auth/providers/auth_provider.dart';

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
      framePath = videoFile.path;
    }

    if (!mounted) return;

    // Show shot type picker, then run analysis + save
    final selection = await _showShotTypePicker(context);
    if (!mounted) return;

    final user = ref.read(firebaseUserProvider).valueOrNull;
    final uid = user?.uid;
    final discipline = selection?.discipline ?? LacrosseDiscipline.mens;
    final shotType = selection?.shotType;

    // Kick off ML analysis
    ref.read(analysisNotifierProvider.notifier).analyze(
          framePath,
          discipline: discipline,
          shotType: shotType,
        );

    // Save session to Firestore in the background
    String sessionId = 'new_${DateTime.now().millisecondsSinceEpoch}';
    if (uid != null) {
      _saveSession(
        uid: uid,
        durationSeconds: _recordingSeconds,
      ).then((id) => sessionId = id);
    }

    if (mounted) {
      context.push(AppRoutes.resultsPath(sessionId));
    }
  }

  Future<String> _saveSession({
    required String uid,
    required int durationSeconds,
  }) async {
    // Wait briefly for analysis to finish so we can persist the score
    await Future.delayed(const Duration(milliseconds: 500));
    final analysisState = ref.read(analysisNotifierProvider);
    final score = analysisState.result?.score ?? 75;
    final goalZone = analysisState.result?.goalZone;
    final breakdown = analysisState.result?.breakdown ?? {};

    final sessionService = ref.read(sessionServiceProvider);
    return sessionService.saveAnalysis(
      uid: uid,
      mode: _mode == RecordingMode.player
          ? SessionMode.player
          : SessionMode.goalie,
      durationSeconds: durationSeconds,
      overallScore: score,
      goalZone: goalZone,
      breakdown: breakdown,
    );
  }

  Future<_ShotTypeSelection?> _showShotTypePicker(BuildContext ctx) {
    return showModalBottomSheet<_ShotTypeSelection>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ShotTypePickerSheet(),
    );
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

// ---------------------------------------------------------------------------
// Shot type picker
// ---------------------------------------------------------------------------

class _ShotTypeSelection {
  final LacrosseDiscipline discipline;
  final ShotType? shotType;
  const _ShotTypeSelection({required this.discipline, this.shotType});
}

class _ShotTypePickerSheet extends StatefulWidget {
  const _ShotTypePickerSheet();

  @override
  State<_ShotTypePickerSheet> createState() => _ShotTypePickerSheetState();
}

class _ShotTypePickerSheetState extends State<_ShotTypePickerSheet> {
  LacrosseDiscipline _discipline = LacrosseDiscipline.mens;

  @override
  Widget build(BuildContext context) {
    final shots = shotsForDiscipline(_discipline);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'What type of shot?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          // Discipline toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PillButton(
                label: "Men's",
                selected: _discipline == LacrosseDiscipline.mens,
                onTap: () => setState(() => _discipline = LacrosseDiscipline.mens),
              ),
              const SizedBox(width: 8),
              _PillButton(
                label: "Women's",
                selected: _discipline == LacrosseDiscipline.womens,
                onTap: () => setState(() => _discipline = LacrosseDiscipline.womens),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Skip button
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _ShotTypeSelection(discipline: _discipline),
            ),
            child: const Text('Skip — auto detect later'),
          ),
          const Divider(height: 1),
          // Shot list
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: shots.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (_, i) {
                final s = shots[i];
                return ListTile(
                  title: Text(s.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(s.quickCue,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.pop(
                    context,
                    _ShotTypeSelection(
                      discipline: _discipline,
                      shotType: s.type,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
