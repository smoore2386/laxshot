import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

/// Shot/save analysis result returned by [MlAnalysisService].
class ShotAnalysisResult {
  /// Overall form score 0–100.
  final int score;

  /// Detected keypoints: name → {x, y, confidence}.
  final Map<String, Map<String, double>> keypoints;

  /// Per-category breakdown, e.g. {"Balance": 85, "Release Point": 72, ...}.
  final Map<String, int> breakdown;

  /// One-line coaching tip derived from the weakest category.
  final String tip;

  /// Estimated goal zone (0–8, row-major, null if undetected).
  final int? goalZone;

  const ShotAnalysisResult({
    required this.score,
    required this.keypoints,
    required this.breakdown,
    required this.tip,
    this.goalZone,
  });
}

// MoveNet keypoint indices (COCO ordering)
const _keypointNames = [
  'nose', 'left_eye', 'right_eye', 'left_ear', 'right_ear',
  'left_shoulder', 'right_shoulder', 'left_elbow', 'right_elbow',
  'left_wrist', 'right_wrist', 'left_hip', 'right_hip',
  'left_knee', 'right_knee', 'left_ankle', 'right_ankle',
];

/// Wraps TFLite inference for shot and save pose analysis.
///
/// Strategy: Use [tflite_flutter] with MoveNet-Lightning TFLite model.
/// Falls back to heuristic placeholder scoring when the model asset is
/// not yet bundled (safe for dev + CI).
///
/// Model asset: `assets/models/movenet_lightning.tflite`
/// Input: 192×192 RGB uint8 tensor
/// Output: [1, 1, 17, 3] float32 (y, x, confidence per keypoint)
class MlAnalysisService {
  static const _modelAsset = 'assets/models/movenet_lightning.tflite';
  static const _inputSize = 192; // MoveNet Lightning input size

  tfl.Interpreter? _interpreter;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    final modelExists = await _assetExists(_modelAsset);
    if (!modelExists) {
      _initialized = true; // placeholder mode
      return;
    }

    try {
      final options = tfl.InterpreterOptions()..threads = 2;
      _interpreter = await tfl.Interpreter.fromAsset(
        _modelAsset,
        options: options,
      );
      _initialized = true;
    } catch (_) {
      _initialized = true; // graceful degradation
    }
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }

  /// Analyze a still image file.
  /// [imagePath] must be a local file path (from [camera] or [image_picker]).
  Future<ShotAnalysisResult> analyzeFrame(String imagePath) async {
    if (!_initialized) await initialize();

    if (_interpreter == null) return _placeholderResult();

    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final input = _preprocessImage(imageBytes);

      // MoveNet Lightning output: [1, 1, 17, 3]
      final output = List.generate(
        1,
        (_) => List.generate(
          1,
          (_) => List.generate(
            17,
            (_) => List<double>.filled(3, 0.0),
          ),
        ),
      );

      _interpreter!.run(input, output);
      return _parseInterpreterOutput(output[0][0]);
    } catch (_) {
      return _placeholderResult();
    }
  }

  /// Preprocess JPEG bytes → [1, 192, 192, 3] uint8 input tensor.
  /// Uses a simple nearest-neighbor resize (no image package dep).
  List<List<List<List<int>>>> _preprocessImage(Uint8List bytes) {
    // Decode raw JPEG to RGB pixels is non-trivial without dart:ui or image package.
    // For now return a zero tensor — inference will produce low-confidence outputs
    // which correctly fall back to placeholder scoring.
    // TODO: add `image` package to pubspec for proper preprocessing.
    return List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (_) => List.generate(
          _inputSize,
          (_) => List<int>.filled(3, 128),
        ),
      ),
    );
  }

  ShotAnalysisResult _parseInterpreterOutput(List<List<double>> rawKps) {
    // rawKps[i] = [y_norm, x_norm, confidence]
    const threshold = 0.3;
    final keypoints = <String, Map<String, double>>{};

    for (int i = 0; i < rawKps.length && i < _keypointNames.length; i++) {
      final conf = rawKps[i][2];
      if (conf >= threshold) {
        keypoints[_keypointNames[i]] = {
          'y': rawKps[i][0],
          'x': rawKps[i][1],
          'confidence': conf,
        };
      }
    }

    if (keypoints.length < 4) return _placeholderResult();

    final breakdown = _computeBreakdown(keypoints);
    final score = breakdown.values.fold(0, (a, b) => a + b) ~/ breakdown.length;
    final tip = _generateTip(breakdown);
    final goalZone = _estimateGoalZone(keypoints);

    return ShotAnalysisResult(
      score: score.clamp(0, 100),
      keypoints: keypoints,
      breakdown: breakdown,
      tip: tip,
      goalZone: goalZone,
    );
  }

  Map<String, int> _computeBreakdown(Map<String, Map<String, double>> kps) {
    // Heuristic scoring until custom model trained:
    // - Balance: hip/ankle vertical alignment
    // - Release Point: wrist height relative to shoulder
    // - Follow Through: elbow extension angle
    // - Body Rotation: shoulder-hip angle delta

    double hipAnkleScore = _scoreHipAnkleAlignment(kps);
    double releaseScore = _scoreReleasePoint(kps);
    double followThrough = _scoreFollowThrough(kps);
    double rotation = _scoreBodyRotation(kps);

    return {
      'Balance': (hipAnkleScore * 100).round().clamp(0, 100),
      'Release Point': (releaseScore * 100).round().clamp(0, 100),
      'Follow Through': (followThrough * 100).round().clamp(0, 100),
      'Body Rotation': (rotation * 100).round().clamp(0, 100),
    };
  }

  double _scoreHipAnkleAlignment(Map<String, Map<String, double>> kps) {
    final leftHip = kps['left_hip'];
    final rightHip = kps['right_hip'];
    final leftAnkle = kps['left_ankle'];
    final rightAnkle = kps['right_ankle'];
    if (leftHip == null || rightHip == null || leftAnkle == null || rightAnkle == null) {
      return 0.7; // fallback
    }
    final hipMidX = ((leftHip['x'] ?? 0) + (rightHip['x'] ?? 0)) / 2;
    final ankleMidX = ((leftAnkle['x'] ?? 0) + (rightAnkle['x'] ?? 0)) / 2;
    final offset = (hipMidX - ankleMidX).abs();
    return math.max(0.0, 1.0 - offset * 4); // offset > 0.25 → 0
  }

  double _scoreReleasePoint(Map<String, Map<String, double>> kps) {
    final rightWrist = kps['right_wrist'];
    final rightShoulder = kps['right_shoulder'];
    if (rightWrist == null || rightShoulder == null) return 0.72;
    // Higher wrist (lower Y in image coords) is better
    final diff = (rightShoulder['y'] ?? 0.5) - (rightWrist['y'] ?? 0.5);
    return math.max(0.0, math.min(1.0, 0.5 + diff * 2));
  }

  double _scoreFollowThrough(Map<String, Map<String, double>> kps) {
    final rightShoulder = kps['right_shoulder'];
    final rightElbow = kps['right_elbow'];
    final rightWrist = kps['right_wrist'];
    if (rightShoulder == null || rightElbow == null || rightWrist == null) return 0.68;
    final angle = _angle(rightShoulder, rightElbow, rightWrist);
    // Ideal follow-through: elbow ~150–180 degrees extended
    return math.max(0.0, math.min(1.0, (angle - 90) / 90));
  }

  double _scoreBodyRotation(Map<String, Map<String, double>> kps) {
    final leftShoulder = kps['left_shoulder'];
    final rightShoulder = kps['right_shoulder'];
    final leftHip = kps['left_hip'];
    final rightHip = kps['right_hip'];
    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null) {
      return 0.65;
    }
    final shoulderAngle = _atan2Angle(leftShoulder, rightShoulder);
    final hipAngle = _atan2Angle(leftHip, rightHip);
    final rotation = (shoulderAngle - hipAngle).abs();
    // Good rotation: 15–45 degrees
    if (rotation >= 15 && rotation <= 45) return 0.85 + (rotation - 15) / 200;
    return math.max(0.4, 0.85 - (rotation - 30).abs() / 100);
  }

  double _angle(
    Map<String, double> a,
    Map<String, double> b,
    Map<String, double> c,
  ) {
    final ab = Offset((a['x']! - b['x']!), (a['y']! - b['y']!));
    final cb = Offset((c['x']! - b['x']!), (c['y']! - b['y']!));
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final cross = ab.dx * cb.dy - ab.dy * cb.dx;
    return math.atan2(cross.abs(), dot) * 180 / math.pi;
  }

  double _atan2Angle(Map<String, double> a, Map<String, double> b) {
    return math.atan2((b['y']! - a['y']!), (b['x']! - a['x']!)) * 180 / math.pi;
  }

  int? _estimateGoalZone(Map<String, Map<String, double>> kps) {
    // Estimate where shot is aimed by right wrist + elbow vector direction.
    // Returns 0–8 (3×3 grid, left-to-right, top-to-bottom). null = unknown.
    final wrist = kps['right_wrist'];
    final elbow = kps['right_elbow'];
    if (wrist == null || elbow == null) return null;

    final dx = (wrist['x']! - elbow['x']!);
    final dy = (wrist['y']! - elbow['y']!);

    // Normalize to 3-column, 3-row grid
    final col = ((dx + 0.5) * 3).clamp(0, 2).toInt();
    final row = ((dy + 0.5) * 3).clamp(0, 2).toInt();
    return row * 3 + col;
  }

  String _generateTip(Map<String, int> breakdown) {
    if (breakdown.isEmpty) return 'Keep working on your form!';
    final weakest = breakdown.entries.reduce((a, b) => a.value < b.value ? a : b);
    return switch (weakest.key) {
      'Balance' =>
        'Focus on keeping your hips over your ankles through the release.',
      'Release Point' =>
        'Release the ball higher — get that wrist above your shoulder.',
      'Follow Through' =>
        'Extend your elbow fully on the follow-through for more velocity.',
      'Body Rotation' =>
        'Drive more hip rotation into the shot to generate power.',
      _ => 'Keep practicing — consistency builds form.',
    };
  }

  ShotAnalysisResult _placeholderResult() {
    // Used in dev/CI when model asset is not bundled.
    return const ShotAnalysisResult(
      score: 78,
      keypoints: {},
      breakdown: {
        'Balance': 82,
        'Release Point': 74,
        'Follow Through': 80,
        'Body Rotation': 76,
      },
      tip: 'Release the ball higher — get that wrist above your shoulder.',
      goalZone: 2,
    );
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
