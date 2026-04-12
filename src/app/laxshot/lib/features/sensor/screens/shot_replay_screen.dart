import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/sensor_session_provider.dart';
import '../widgets/shot_score_ring.dart';

class ShotReplayScreen extends ConsumerStatefulWidget {
  final int shotIndex;

  const ShotReplayScreen({super.key, required this.shotIndex});

  @override
  ConsumerState<ShotReplayScreen> createState() => _ShotReplayScreenState();
}

class _ShotReplayScreenState extends ConsumerState<ShotReplayScreen> {
  double _scrubPosition = 0; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sensorSessionProvider);
    if (widget.shotIndex >= session.shots.length) {
      return const Scaffold(body: Center(child: Text('Shot not found')));
    }

    final shot = session.shots[widget.shotIndex];
    final packets = shot.packets;

    // Current packet based on scrub position
    final currentIdx =
        packets.isEmpty ? 0 : (_scrubPosition * (packets.length - 1)).round();
    final currentPacket = packets.isNotEmpty ? packets[currentIdx] : null;

    // Find release point index (last packet)
    final releaseIdx = packets.length - 1;
    final releasePosition =
        packets.length > 1 ? releaseIdx / (packets.length - 1) : 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Shot #${widget.shotIndex + 1} Replay'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            // Score badge
            ShotScoreRing(score: shot.shotScore, size: 100),
            const SizedBox(height: AppSizes.md),

            // 3D stick wireframe
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: currentPacket != null
                      ? CustomPaint(
                          size: Size.infinite,
                          painter: _StickWireframePainter(
                            quatW: currentPacket.quatW,
                            quatX: currentPacket.quatX,
                            quatY: currentPacket.quatY,
                            quatZ: currentPacket.quatZ,
                            accelMag: currentPacket.accelMagnitude,
                            isRelease: currentIdx == releaseIdx,
                          ),
                        )
                      : const Center(
                          child: Text('No packet data for replay'),
                        ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // Timeline scrubber
            Column(
              children: [
                Stack(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.surfaceVariant,
                        thumbColor: AppColors.primary,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16),
                      ),
                      child: Slider(
                        value: _scrubPosition,
                        onChanged: (v) => setState(() => _scrubPosition = v),
                      ),
                    ),
                    // Release point marker
                    if (packets.length > 1)
                      Positioned(
                        left: 24 +
                            (MediaQuery.of(context).size.width -
                                    AppSizes.md * 2 -
                                    48) *
                                releasePosition,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: AppColors.error.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Start',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Release',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'End',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSizes.sm),

            // Current packet metrics
            if (currentPacket != null)
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MetricChip(
                        label: 'Accel',
                        value:
                            '${currentPacket.accelMagnitude.toStringAsFixed(1)}g'),
                    _MetricChip(
                        label: 'Gyro',
                        value:
                            '${currentPacket.gyroMagnitude.toStringAsFixed(0)}°/s'),
                    _MetricChip(
                        label: 'Pitch',
                        value:
                            '${currentPacket.pitchDeg.toStringAsFixed(1)}°'),
                  ],
                ),
              ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Custom painter that draws a lacrosse stick wireframe rotated by quaternion.
class _StickWireframePainter extends CustomPainter {
  final double quatW, quatX, quatY, quatZ;
  final double accelMag;
  final bool isRelease;

  _StickWireframePainter({
    required this.quatW,
    required this.quatX,
    required this.quatY,
    required this.quatZ,
    required this.accelMag,
    required this.isRelease,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Convert quaternion to rotation matrix (simplified 2D projection)
    // Extract pitch and yaw for 2D display
    final pitch = math.asin(
        (2.0 * (quatW * quatY - quatZ * quatX)).clamp(-1.0, 1.0));
    final yaw = math.atan2(
        2.0 * (quatW * quatZ + quatX * quatY),
        1.0 - 2.0 * (quatY * quatY + quatZ * quatZ));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pitch);

    // Stick handle (shaft)
    final handleLength = size.height * 0.35;
    final handlePaint = Paint()
      ..color = isRelease ? AppColors.error : AppColors.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, handleLength * 0.3),
      Offset(0, -handleLength * 0.7),
      handlePaint,
    );

    // Stick head (simplified triangle/scoop shape)
    final headTop = -handleLength * 0.7;
    final headWidth = size.width * 0.12;
    final headHeight = handleLength * 0.25;

    final headPaint = Paint()
      ..color = (isRelease ? AppColors.error : AppColors.primary)
          .withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final headOutlinePaint = Paint()
      ..color = isRelease ? AppColors.error : AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final headPath = Path()
      ..moveTo(0, headTop)
      ..lineTo(-headWidth, headTop - headHeight * 0.4)
      ..quadraticBezierTo(
          -headWidth * 1.1, headTop - headHeight, 0, headTop - headHeight)
      ..quadraticBezierTo(
          headWidth * 1.1, headTop - headHeight, headWidth, headTop - headHeight * 0.4)
      ..close();

    canvas.drawPath(headPath, headPaint);
    canvas.drawPath(headPath, headOutlinePaint);

    // Speed indicator — lines radiating from head based on accel
    if (accelMag > 3) {
      final speedAlpha = (accelMag / 20.0).clamp(0.1, 0.6);
      final speedPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: speedAlpha)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      final speedLength = size.width * 0.06 * (accelMag / 10.0).clamp(0.5, 2.0);
      for (int i = -1; i <= 1; i++) {
        final y = headTop - headHeight * 0.5 + i * 8;
        canvas.drawLine(
          Offset(headWidth + 4, y),
          Offset(headWidth + 4 + speedLength, y - 3),
          speedPaint,
        );
      }
    }

    // Release point indicator
    if (isRelease) {
      canvas.drawCircle(
        Offset(0, headTop - headHeight * 0.5),
        8,
        Paint()
          ..color = AppColors.error.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(0, headTop - headHeight * 0.5),
        8,
        Paint()
          ..color = AppColors.error
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    canvas.restore();

    // Yaw indicator arrow at bottom
    final arrowCenter = Offset(center.dx, size.height - 30);
    canvas.save();
    canvas.translate(arrowCenter.dx, arrowCenter.dy);
    canvas.rotate(yaw);
    canvas.drawLine(
      const Offset(0, 8),
      const Offset(0, -8),
      Paint()
        ..color = AppColors.textSecondary
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    // Arrow tip
    canvas.drawLine(
      const Offset(0, -8),
      const Offset(-4, -2),
      Paint()
        ..color = AppColors.textSecondary
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(0, -8),
      const Offset(4, -2),
      Paint()
        ..color = AppColors.textSecondary
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StickWireframePainter old) =>
      old.quatW != quatW ||
      old.quatX != quatX ||
      old.quatY != quatY ||
      old.quatZ != quatZ ||
      old.isRelease != isRelease;
}
